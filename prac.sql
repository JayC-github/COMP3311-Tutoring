-- COMP3311 Prac 03 Exercise
-- Schema for simple company database

create table Employees (
	tfn         char(11) check (tfn ~'[0-9]{3}-[0-9]{3}-[0-9]{3}'),
	givenName   varchar(30) not null,
	familyName  varchar(30),
	hoursPweek  float check (hoursPweek between 0 and 168),
	primary key	(tfn)
);

create table Departments (
	id          char(3),
	name        varchar(100) not null unique,
	manager     char(11) not null unique,
	foreign key (manager) references Employees(tfn),
	primary key (id)
);


create table DeptMissions (
	department  char(3),
	keyword     varchar(20),
	foreign key (department) references Departments(id),
	primary key (department, keyword)
);


create table WorksFor (
	employee    char(11) not null, -- total participation
	department  char(3),
	percentage  float check (percentage between 0 and 100),
	foreign key (employee) references Employees(tfn),
	foreign key (department) references Departments(id),
	primary key (employee, department)
);
