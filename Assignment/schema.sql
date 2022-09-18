-- COMP3311 20T3 Assignment 1
-- Calendar schema
-- Written by Jianjun(Jay) Chen z5261536

-- Types

create type AccessibilityType as enum ('read-write','read-only','none');
create type InviteStatus as enum ('invited','accepted','declined');

-- add more types/domains if you want
-- visibility of the events
create type Visibility as enum ('public','private');
-- day_of_week attribute in the entity weekly_events and monthly_by_day_events
create type DayOfWeek as enum ('mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun');

-- Tables

/*
1. In the attribute is_admin, 'Y' represent Yes and 'N' represnet No, is_admin should not be null
2. name and email is not null, email address should be unique
3. non-empty password (not null)
*/
create table Users (
	id			serial,
	name        text not null,
	email       text not null unique,
	password    text not null,
	is_admin    char(1) not null check (is_admin in ('Y','N')),
	primary key (id)
);

-- Each group must be owned by a user, who maintains the list of memebers (1:N relationship)
create table Groups (
	id          serial,
	name        text not null,
	owner       integer not null, -- total participation
	primary key (id),
    foreign key (owner) references Users(id)
);

-- User can be a member of 0 to many groups, each group can have 0 to many users (N:M relationship)
create table Members (
	user_id     integer,
	group_id    integer,
	primary key (user_id, group_id),
    foreign key (user_id) references Users(id),
	foreign key (group_id) references Groups(id)
);

/*
1. Assume the name and the color of the calendar cannot be null, set by its owner
2. default_access can not be null, it can be 'read-write', 'read-only' and 'none'
3. Each calendar must be onwed by a user, a user may own many calendars (1:N relationship)
*/
create table Calendars (
	id		    serial,
	name        text not null,
	colour      text not null,
	default_access AccessibilityType not null,
	owner       integer not null, -- total participation
	primary key (id),
    foreign key (owner) references Users(id)

);

/*
1. User can access 0 to many calendars, a calendar can be accessed by 0 to many users (N:M relationship)
2. access can not be null
*/
create table Accessibility (
	user_id 	integer,
    calendar_id	integer,
	access		AccessibilityType not null,
	primary key (user_id, calendar_id),
    foreign key (user_id) references Users(id),
	foreign key (calendar_id) references Calendars(id)
);

/*
1. User can subsribe 0 to many calendars, a calendar can be subscribed by 0 to many users (N:M relationship)
2. Each calendar has a colour, but a subscriber may or may not set a different colour for their own view
*/
create table Subscribed (
    user_id 	integer,
    calendar_id	integer,
	colour		text,
    primary key (user_id, calendar_id),
	foreign key (user_id) references Users(id),
	foreign key (calendar_id) references Calendars(id)
);

/*
1. Assume an event must have a title and visibility, but may not be associated with a location
2. Assume an event may not have a start time and an end time (ie.birthday)
3. Each event must be created by one user(1:N relationship)
4. Each event must be a part of the calendar (1:N relationship)
*/
create table Events (
	id			serial,
	title		text not null,
	visibility  Visibility not null,
	location	text,
	start_time  time,
	end_time	time,
	created_by	integer not null, -- total participation
	part_of 	integer not null, -- total participation
	primary key (id),
    foreign key (created_by) references Users(id),
	foreign key (part_of) references Calendars(id)
);

/*
1. Mapping multi-valued attributes alarms of the entity Event
in the SQL schema these names should be written in singular form
2. Alarm is implicity not null since it is part of the primary key
3. Alarm type is time interval
*/
create table Alarms (
	event_id	integer,
	alarm		interval,
    primary key (event_id, alarm),
	foreign key (event_id) references Events(id)
);

-- One day event has a date
create table One_day_events (
	event_id	integer,
	date        date not null, 
    primary key (event_id),
	foreign key (event_id) references Events(id)
);

-- Spnning event has a start date and an end date
create table Spanning_events (
	event_id	integer,
	start_date  date not null,
	end_date	date not null, 
    primary key (event_id),
	foreign key (event_id) references Events(id)
);
/*
1. Recurring event has a starting date and may not have an ending date (assume ending date can be null)
2. ntimes may be null but if it has, should be positive
*/
create table Recurring_events (
	event_id	integer,
	start_date  date not null,
	end_date	date,
	ntimes      integer check (ntimes > 0),
    primary key (event_id),
	foreign key (event_id) references Events(id)
);

/*
1. day of week has to be mon..sun
2. frequency has to be positive integer (1,2,3..)
3. day_of_week	char(3) not null check (day_of_week in ('mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun')), -> create a new type
*/
create table Weekly_events (
	recurring_event_id integer,
	day_of_week	DayOfWeek not null,
	frequency	integer not null check (frequency > 0),
    primary key (recurring_event_id),
	foreign key (recurring_event_id) references Recurring_events(event_id)
);

/*
1. day of week has to be mon..sun
2. week in month should be between 1 and 5
*/
create table Monthly_by_day_events (
	recurring_event_id integer,
	day_of_week	DayOfWeek not null,
	week_in_month integer not null check (week_in_month between 1 and 5),
    primary key (recurring_event_id),
	foreign key (recurring_event_id) references Recurring_events(event_id)
);

-- Date in month should be between 1 and 31
create table Monthly_by_date_events (
	recurring_event_id integer,
	date_in_month	integer not null check (date_in_month between 1 and 31),
    primary key (recurring_event_id),
	foreign key (recurring_event_id) references Recurring_events(event_id)
);

-- treate the year of the date as the starting year
create table Annual_events (
	recurring_event_id integer,
	date		date not null,
    primary key (recurring_event_id),
	foreign key (recurring_event_id) references Recurring_events(event_id)
);

-- an event can have an associated list of users who are invited (N:M relationship)
create table Invited (
	event_id	integer,
	user_id		integer,
	status      InviteStatus not null,
	primary key (event_id, user_id),
    foreign key (event_id) references Events(id),
	foreign key (user_id) references Users(id)
);


-- etc. etc. etc.