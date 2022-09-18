-- COMP3311 20T3 Ass3 ... extra database definitions
-- add any views or functions you need to this file

create type Role as (name text, role_play text);

-- function returns the names and the roles of each cast and crew in a specific movie
-- roleType = Acting_roles or Crew_roles
-- rolePlayed = played or role
-- mid = the movie id
create or replace function
    principals(roleType text, rolePlayed text, mid integer) returns setof Role
as $$
declare
    query text;
    person_role Role;
    p_name text;
    p_role text;
begin
    query := 'select n.name, ac.' || quote_ident(rolePlayed);
    query := query || ' from Names n join Principals p on (n.id = p.name_id)';
    query := query || ' join ' || quote_ident(roleType) || ' ac on (ac.movie_id = p.movie_id and ac.name_id = n.id)';
    query := query || ' where p.movie_id = ' || quote_literal(mid);
    query := query || ' order by p.ordering, ac.' || quote_ident(rolePlayed);
    
    for p_name, p_role in execute query
    loop
        person_role = (p_name, p_role);
        return next person_role;
    end loop;
    return;
end;
$$ language plpgsql;


-- function return the acting roles and the crew roles for a specific person in a specific movie 
-- roleType = Acting_roles or Crew_roles
-- rolePlayed = played or role
-- mid = the movie id, nid = the name id 
create or replace function
    roles(roleType text, rolePlayed text, mid integer, nid integer) returns setof text
as $$
declare
    query text;
    result text;
begin
    query:= 'select ac.' || quote_ident(rolePlayed) || ' from ' || quote_ident(roleType) || ' ac';
    query:= query || ' join Principals p on (ac.movie_id = p.movie_id and ac.name_id = p.name_id)';
    query:= query || ' where p.movie_id = ' || quote_literal(mid) || ' and p.name_id = ' || quote_literal(nid);
    query:= query || ' order by p.ordering, ac.' || quote_ident(rolePlayed);

    for result in execute query
    loop
        return next result;
    end loop;
    return;
end;
$$ language plpgsql;