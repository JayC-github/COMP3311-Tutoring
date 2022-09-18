create assertion manager check (
    not exists (
        select * from Employee e join Department d on (e.id = d.manager)
        where e.work_in != d.id
    )
);

create assertion manager check (
    not exists (
        select * from Employee e join Department d on (e.work_in = d.id)
        join Employee mgr on (d.manager = mgr.id)
        where e.salary > mgr.salary
    )
);

create trigger lol before insert or update on
xxx for each row execute procedure timestam();

create table (
    empname text primary key,
    salary integer,
    last_date timestamp,
    last_user text
);
create function emp_stamp() returns trigger
as $$
begin
    if new.empname is null or new.salary is null then
        raise exception 'can''t be null';
    end if;

    if new.salary < 0 then 
        raise exception '% cannot have a negative salary', new.empname;
    
    new.last_date = now();
    new.last_user = user();
    return new;
end;
$$ language plpgsql;

create or replace function ins_stu() returns trigger as $$
begin
    update Course set numStudents = numStudents + 1
    where code = new.course;
    return new;
end;
$$ language plpgsql;

create or replace function del_stu() returns trigger as $$
begin
    update Course set numStudents = numStudents - 1
    where code = old.course;
    return old;
end;
$$ language plpgsql;


create or replace function upd_stu() returns trigger as $$
begin
    update Course set numStudents = numStudents + 1
    where code = new.course;
    update Course set numStudents = numStudents - 1
    where code = old.course;
    return new;
end;
$$ language plpgsql;

create or replace function check_quota() returns trigger as $$
declare
    _quota integer;
    stuNum integer;
begin
    select numStudents, quota into stuNum, _quote 
    from Course where code = new.course;
    if (numStudents >= quota) then
        raise exception 'class % is full', new.course;
    end if;
    return new;
end;
$$ language plpgsql;

create trigger xxx after insert/delete/update on enrolment
    for each row execute procedure xxx();

create trigger check_quota before insert or update on enrolment
    for each row execute procedure check_quota();

-- relational algebra
a. find the name of suppliers who supply some red part
select s.sname from Suppliers s join Catalog c on (s.sid = c.supplier)
join Parts p on (c.part = p.id)
where p.colour = 'red';

Tmp1 = Proj[id](Sel[colour='red'](Parts))
Tmp2 = Proj[supplier](Tmp1 join Catalog)
Result = Proj[sname](Suppliers join Tmp2)

Tmp1 = Proj[id](Sel[colour='red' OR colour='green'](Parts))
Result = Proj[sid](Tmp1)

e. find the sid of sppuliers who supply every part
AllpartIDS = Proj[pid](Parts)
PartSuppliers = Proj[sid, pid](Catalog)
Answer = PartSuppliers div AllpartIDS