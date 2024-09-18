--1
/*
CREATE FUNCTION course_count (i varchar(5))
RETURNS integer
LANGUAGE plpgsql as $$
DECLARE t_count integer;
BEGIN
	SELECT count(course_id) INTO t_count
	FROM takes
	WHERE takes.id = i;
	RETURN t_count;
END;
$$;
select course_count('12345');
select id,course_count(id) from student;
*/


--2
/*
CREATE FUNCTION course_count_2 (i varchar(5), d_name varchar(20))
RETURNS INTEGER
LANGUAGE plpgsql as $$
DECLARE "result" integer;
BEGIN
	SELECT count(course_id) into "result"
	FROM takes NATURAL JOIN course
	WHERE dept_name = d_name AND "id" = i;
	RETURN "result";
END;
$$;

select course_count_2('12345','Comp. Sci.');
select id,name,course_count_2(id,'Comp. Sci.') from student;
*/


--3
/*
CREATE FUNCTION course_count (i varchar(5), d_name varchar(20) DEFAULT 'Comp. Sci.')
RETURNS INTEGER
LANGUAGE plpgsql as $$
DECLARE "result" integer;
BEGIN
	SELECT count(course_id) into "result"
	FROM takes NATURAL JOIN course
	WHERE dept_name = d_name AND "id" = i;
	RETURN "result";
END;
$$;
*/


--4
