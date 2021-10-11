-- COMP3311 20T3 Assignment 2
-- z5261536

-- Q1: students who've studied many courses (> 65)

-- Each student and the number of courses they has studied
create or replace view nCourses(student, ncourses)
as 
select student, count(*) 
from Course_enrolments 
group by student
;

-- student who has studied more than 65 courses
create or replace view Q1(unswid,name)
as
select p.unswid, p.name 
from People p join nCourses n on (p.id = n.student)
where ncourses > 65
;

-- Q2: numbers of students, staff and both

create or replace view Q2(nstudents,nstaff,nboth)
as
with 
   -- students who are not staff
   nStudents as ((select id from Students) except (select id from staff)), 
   -- staff who are not students
   nStaff as ((select id from Staff) except (select id from Students)),
   -- people who are both staff and student
   nBoth as ((select id from Staff) intersect (select id from Students))
   
select (select count(*) from nStudents), (select count(*) from nStaff), (select count(*) from nBoth)
;

-- Q3: prolific Course Convenor(s)

-- Each person(staff) and the number of courses they have been LIC for 
create or replace view nLic(staff, ncourses)
as
select c.staff, count(*)
from course_staff c join Staff_roles s on (c.role = s.id) 
where s.name = 'Course Convenor'
group by c.staff
;

-- The person(s) who has been LIC of the most courses and the number of the courses;
create or replace view Q3(name,ncourses)
as
select p.name, n.ncourses from People p join nLic n on (p.id = n.staff)
where n.ncourses = (select max(ncourses) from nLic)
;

-- Q4: Comp Sci students in 05s2 and 17s1

create or replace view Q4a(id, name)
as
select distinct(p.unswid), p.name 
from People p join Program_enrolments e on (p.id = e.student)
join Programs pg on (e.program = pg.id)
join Terms t on (e.term = t.id)
where pg.code = '3978' and t.year::text like '%05' and t.session = 'S2'
;

create or replace view Q4b(id, name)
as
select distinct(p.unswid), p.name 
from People p join Program_enrolments e on (p.id = e.student)
join Programs pg on (e.program = pg.id)
join Terms t on (e.term = t.id)
where pg.code = '3778' and t.year::text like '%17' and t.session = 'S1'
;

-- Q5: most "committee"d faculty

-- Each faculty and the number of committes of them
create or replace view nCommittees(id, ncomm)
as 
select facultyOf(o.id), count(*) 
from OrgUnits o join OrgUnit_types t on (o.utype = t.id)
where t.name = 'Committee' and facultyOf(o.id) is not null 
group by facultyof(o.id)
;

-- faculty with the maximum number of committees
create or replace view Q5(name)
as
select o.name from OrgUnits o join nCommittees n on (o.id = n.id) 
where ncomm = (select max(ncomm) from nCommittees)
;

-- Q6: nameOf function
-- take a parameter an id or unswid of a person and return his/her name

create or replace function
   Q6(_id integer) returns text
as $$
   select p.name from People p where p.id = _id or p.unswid = _id; 
$$ language sql;

-- Q7: offerings of a subject
-- take a parameter a UNSW subject code and returns all offerings of the subject for which CC is known

create or replace function
   Q7(_subject text)
     returns table (subject text, term text, convenor text)
as $$
   select s.code::text, termName(c.term), p.name
   from Subjects s join Courses c on (s.id = c.subject) 
   join Course_staff cs on (c.id = cs.course)
   join Staff_roles sr on (cs.role = sr.id)
   join People p on (p.id = cs.staff)
   where s.code::text = _subject and sr.name = 'Course Convenor';
$$ language sql;


-- Q8: transcript

-- given a grade, check whether a student has passed the course or not 
create or replace function 
   IsPassed(grade GradeType) returns boolean
as $$
declare 
   result boolean;
begin 
   if (grade in ('SY', 'PT', 'PC', 'PS', 'CR', 'DN', 'HD', 'A', 'B', 'C', 'XE', 'T', 'PE', 'RC', 'RS')) then 
      result := TRUE;
   else
      result := FALSE;
   end if;
      return result;
end;
$$ LANGUAGE plpgsql;

-- take a student id(unswid) and produces a transcript
create or replace function
   Q8(zid integer) returns setof TranscriptRecord
as $$
declare 
   r TranscriptRecord;
   weightedSumOfMarks float := 0;
   totalUOC integer := 0;
   UOCpassed integer := 0;
begin 
   -- check whether the zid is invalid
   perform * from People p join Students s on (p.id = s.id)
   where p.unswid = zid;
   if (not found) then 
      raise exception 'Invalid student %', zid;
   end if;

   -- code, term, prog, name, mark, grade, uoc
   for r in 
      select s.code, termName(c.term), pg.code, substr(s.name, 1, 20), ce.mark, ce.grade, s.uoc
      from People p join Course_enrolments ce on (p.id = ce.student)
      join Courses c on (ce.course = c.id)
      join Subjects s on (c.subject = s.id)
      join Program_enrolments pe on (p.id = pe.student and pe.term = c.term)
      join Programs pg on (pe.program = pg.id)
      where p.unswid = zid
      order by termName(c.term), s.code -- order by terms.starting
   loop
      -- if student completed the course(even failed) and got a mark, count into the wam calculation
      if (r.mark is not null and r.uoc is not null) then
         totalUOC := totalUOC + r.uoc;
         weightedSumOfMarks := weightedSumOfMarks + r.mark * r.uoc;
      end if;
      
      -- student has not passed this course, set the uoc to null (only display UOC when student passed)
      if (IsPassed(r.grade) = FALSE) then
         r.uoc := null;
      -- student has passed this course, count into the UOCpassed
      else 
         UOCpassed := UOCpassed + r.uoc;
      end if;
      
      return next r;
   end loop;      
   
   -- if no course has been completed
   if (totalUOC = 0 or weightedSumOfMarks = 0) then      
      r := (null, null, null, 'No WAM available', null, null, null);
   else 
      r := (null, null, null, 'Overall WAM/UOC', weightedSumOfMarks / totalUOC, null, UOCpassed);
   end if;
   
   return next r;
   return;
end;
$$ language plpgsql;


-- Q9: members of academic object group
-- take the id of an academic object group and returns the codes for all members of the aog
-- include the child groups

-- function almost complete Q9 but return some duplicate objcode
create or replace function
   Q9abc(gid integer) returns setof AcObjRecord
as $$
declare
   _gtype text;
   _gdefby text;
   _definition text;
   _negated boolean;
   -- for dynamic commands
   query text;
   rec AcObjRecord;
   _objcode text;
   _subjcode text;
begin

   -- get the gtype, gdefby, definition and negated of an acad_object_groups by its group id
   select a.gtype, a.gdefBy, a.definition, a.negated 
   into _gtype, _gdefby, _definition, _negated
   from Acad_object_groups a where a.id = gid;

   -- if groups are defined by enumerated 
   -- quote_ident(_gtype) = program/stream/subject
   if (_gdefby = 'enumerated' and _negated = FALSE) then
      query := 'select distinct(ps.code) from ' || quote_ident(_gtype) || 's ps';
      query := query || ' join ' || quote_ident(_gtype) || '_group_members gm on (ps.id = gm.' || quote_ident(_gtype) || ')'; 
      query := query || ' join Acad_object_groups aog on (gm.ao_group = aog.id)';
      query := query || ' where aog.id = ' || quote_literal(gid) || ' or aog.parent = ' || quote_literal(gid);

      for _objcode in execute query
      loop
         rec := (_gtype, _objcode);
         return next rec;
      end loop;

   -- if groups are defined by pattern, use the definition
   elsif (_gdefby = 'pattern' and _negated = FALSE) then
      -- program's definition: eg. 8411,8416
      -- only need to get each program code seperated by comma using regexp
      if (_gtype = 'program') then
         for _objcode in
            select * from regexp_split_to_table(_definition, ',')
         loop
            rec := (_gtype, _objcode);  
            return next rec;
         end loop;
      
      -- subject's definition: eg. COMP2###, COMP[34]###, (COMP|SENG|BINF)2###  
      elsif (_gtype = 'subject') then
         -- replace all '#' and 'x' to '.'
         _definition := replace(replace(_definition, '#', '.'), 'x', '.');
         -- replace all ';' to ',' and remove '{', '}'
         _definition := replace(replace(replace(_definition, ';', ','), '{', ''), '}', '');

         for _subjcode in
            select * from regexp_split_to_table(_definition, ',')
         loop
            -- ignore the group pattern which includes 'FREE', 'GEN' or 'F=' as a substring
            for _objcode in
               select distinct(code) from Subjects 
               where code ~ _subjcode and code !~ 'FREE' and code !~'GEN' and code !~'F='
            loop
               rec := (_gtype, _objcode);
               return next rec;
            end loop;
         end loop;   
      end if;
   end if;
end;
$$ language plpgsql;

-- use distinct to remove duplicate objcode from Q9abc()
create or replace function
   Q9(gid integer) returns setof AcObjRecord
as $$
declare
   rec AcObjRecord;
   _objtype text;
   _objcode text;
begin
   -- check if non-existent group ID
   perform * from Acad_object_groups where id = gid;
   if (not found) then
      raise exception 'No such group %', gid;
      return;
   end if;
   
   -- get the objtype (program/stream/subject)
   select distinct(objtype) into _objtype 
   from Q9abc(gid);

   -- get the list of distinct objcode
   for _objcode in
      select distinct(objcode) from Q9abc(gid)
   loop
      rec := (_objtype, _objcode);
      return next rec;
   end loop;
   return;
end;
$$ language plpgsql;


-- Q10: follow-on courses
-- take a subject code and reutrns all subjects that include this subject in their pre-reqs
create or replace function
   Q10(_code text) returns setof text
as $$
declare
   result text; 
begin  
   for result in 
      select distinct(s.code) 
      from Subjects s join Subject_prereqs sp on (s.id = sp.subject)
      join Rules r on (sp.rule = r.id)
      join Acad_object_groups aog on (r.ao_group = aog.id)
      where aog.definition ~ _code
   loop
      return next result;
   end loop;
   return;
end;
$$ language plpgsql;