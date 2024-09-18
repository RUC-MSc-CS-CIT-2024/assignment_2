-- GROUP: cit11, MEMBERS: Ida Hay Jørgensen, Julius Krüger Madsen, Marek Laslo, Sofus Hilfling Nielsen
-- 1
CREATE OR REPLACE FUNCTION course_count (student_id VARCHAR) 
RETURNS INTEGER
AS $$
  SELECT COUNT(course_id)
  FROM takes 
  WHERE id = student_id;
$$
LANGUAGE sql;


SELECT course_count('12345');
SELECT id, course_count(id) FROM student;

-- 2
CREATE OR REPLACE FUNCTION course_count_2 (student_id VARCHAR, department_name VARCHAR) 
RETURNS INTEGER
AS $$
  SELECT COUNT(course_id)
  FROM takes
  NATURAL JOIN course
  WHERE id = student_id
    AND dept_name = department_name;
$$
LANGUAGE sql;


SELECT course_count_2('12345','Comp. Sci.');
SELECT id,name,course_count_2(id,'Comp. Sci.') FROM student;

-- 3
-- Function that takes either student id together with optional department name
-- if department name is not set the function will return all courses for that student
-- else it will return the number of courses 
-- alternative way of doing this would be to use an OR statement in the where clause
-- but I find the if statement seperate the logic in a better way
DROP FUNCTION IF EXISTS course_count;
CREATE OR REPLACE FUNCTION course_count (student_id VARCHAR(5),
                                          department_name VARCHAR(20) DEFAULT NULL) 
RETURNS INTEGER
AS $$
DECLARE
  course_total INTEGER;
BEGIN
  IF department_name IS NULL THEN
    SELECT COUNT(course_id)
    INTO course_total
    FROM takes 
    WHERE id = student_id;
  ELSE
    SELECT COUNT(course_id)
    INTO course_total
    FROM takes 
    NATURAL JOIN course
    WHERE id = student_id
      AND dept_name = department_name;
  END IF;
  
  RETURN course_total;
END;
$$
LANGUAGE plpgsql;


SELECT course_count('12345'); 
SELECT course_count('12345','Comp. Sci.');

-- 4
CREATE OR REPLACE FUNCTION department_activities (department_name VARCHAR(50)) 
RETURNS TABLE(
  instructor_name VARCHAR(20),
  title VARCHAR(50),
  semester VARCHAR(6),
  "year" NUMERIC(4)
)
AS $$
  SELECT "name", course.title, teaches.semester, teaches."year"
  FROM instructor 
  NATURAL JOIN teaches
  JOIN course USING(course_id)
  WHERE course.dept_name = department_name;
$$
LANGUAGE sql;


SELECT department_activities('Comp. Sci.');

-- 5
CREATE OR REPLACE FUNCTION activities (param VARCHAR(50)) 
RETURNS TABLE(
  department_name VARCHAR(20),
  instructor_name VARCHAR(20),
  course_title VARCHAR(50),
  semester VARCHAR(6),
  "year" NUMERIC(4)
)
AS $$
  SELECT i.dept_name, "name", title, te.semester, te."year"
  FROM department
  NATURAL JOIN instructor AS i
  NATURAL JOIN teaches AS te
  JOIN course USING(course_id)
  WHERE i.dept_name = param OR building = param;
$$
LANGUAGE sql;


SELECT activities('Comp. Sci.');
SELECT activities('Watson');

-- 6
CREATE OR REPLACE FUNCTION followed_courses_by (student_name VARCHAR(20)) 
RETURNS TEXT
AS $$
DECLARE
  "result" TEXT;
  next_instructor VARCHAR(20);
  cur CURSOR FOR 
    SELECT DISTINCT i."name"
    FROM student AS s
    JOIN takes AS ta ON s."id" = ta."id"
    JOIN teaches AS te ON 
      te.course_id = ta.course_id
      AND te.sec_id = ta.sec_id
      AND te.semester = ta.semester
      AND te.year = ta.year
    JOIN instructor AS i ON i."id" = te."id"
    WHERE s."name" = student_name;
BEGIN
  OPEN cur;
  LOOP
    FETCH NEXT FROM CUR INTO next_instructor;
    EXIT WHEN NOT FOUND;
    IF "result" IS NULL THEN
      "result" := next_instructor;
    ELSE
      "result" := "result" || ', ' || next_instructor;
    END IF;
  END LOOP;
  CLOSE cur;
  RETURN "result";
END;
$$
LANGUAGE plpgsql;


SELECT followed_courses_by('Levy');
SELECT followed_courses_by('Shankar');
SELECT "name", followed_courses_by("name") FROM student;

-- 7
CREATE OR REPLACE FUNCTION followed_courses_by (student_name VARCHAR(20)) 
RETURNS TEXT
AS $$
DECLARE
  "result" TEXT;
  next_instructor VARCHAR(20);
BEGIN
  FOR next_instructor IN 
    SELECT DISTINCT i."name"
    FROM student AS s
    JOIN takes AS ta ON s."id" = ta."id"
    JOIN teaches AS te ON 
      te.course_id = ta.course_id
      AND te.sec_id = ta.sec_id
      AND te.semester = ta.semester
      AND te.year = ta.year
    JOIN instructor AS i ON i."id" = te."id"
    WHERE s."name" = student_name
  LOOP
    IF "result" IS NULL THEN
      "result" := next_instructor;
    ELSE
      "result" := "result" || ', ' || next_instructor;
    END IF;
  END LOOP;
  RETURN "result";
END;
$$
LANGUAGE plpgsql;


SELECT followed_courses_by('Shankar');
SELECT "name", followed_courses_by("name") FROM student;

-- 8
CREATE OR REPLACE FUNCTION followed_courses_by (student_name VARCHAR(20)) 
RETURNS TEXT
AS $$
  SELECT string_agg(DISTINCT i."name", ', ')
  FROM student AS s
  JOIN takes AS ta ON s."id" = ta."id"
  JOIN teaches AS te ON 
    te.course_id = ta.course_id
    AND te.sec_id = ta.sec_id
    AND te.semester = ta.semester
    AND te.year = ta.year
  JOIN instructor AS i ON i."id" = te."id"
  WHERE s."name" = student_name;
$$
LANGUAGE sql;


SELECT followed_courses_by('Shankar');
SELECT "name", followed_courses_by("name") FROM student;

-- 9
CREATE OR REPLACE FUNCTION taught_by (student_name VARCHAR(20)) 
RETURNS TEXT
AS $$
  WITH taught_by
    AS ((SELECT i."name"
    FROM student AS s
    JOIN takes AS ta ON s."id" = ta."id"
    JOIN teaches AS te ON 
      te.course_id = ta.course_id
      AND te.sec_id = ta.sec_id
      AND te.semester = ta.semester
      AND te.year = ta.year
    JOIN instructor AS i ON i."id" = te."id"
    WHERE s."name" = student_name)
  UNION
  (SELECT i."name"
    FROM student AS s
    JOIN advisor AS ad ON s."id" = ad.s_id
    JOIN instructor AS i ON i."id" = ad.i_id
    WHERE s."name" = student_name))
  SELECT string_agg("name", ', ') FROM taught_by
$$
LANGUAGE sql;


SELECT taught_by('Shankar');
SELECT "name", taught_by("name") FROM student;

-- 10
ALTER TABLE student
  ADD COLUMN teachers TEXT;

UPDATE student AS s
SET teachers = taught_by(s."name");

CREATE FUNCTION advisor_update_student_teachers_trigger()
RETURNS TRIGGER
AS $$
BEGIN
  UPDATE student AS s
  SET teachers = taught_by(s."name")
  WHERE s."id" = NEW.s_id;
  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE FUNCTION takes_update_student_teachers_trigger()
RETURNS TRIGGER
AS $$
BEGIN
  UPDATE student AS s
  SET teachers = taught_by(s."name")
  WHERE s."id" = NEW."id";
  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER trigger_advisor_insert
AFTER INSERT ON advisor
FOR ROW EXECUTE FUNCTION advisor_update_student_teachers_trigger();

CREATE TRIGGER trigger_takes_insert
AFTER INSERT ON takes
FOR ROW EXECUTE FUNCTION takes_update_student_teachers_trigger();


SELECT id, "name", teachers, followed_courses_by("name") FROM student;
INSERT INTO takes VALUES ('12345', 'BIO-101', '1', 'Summer', '2017', 'A');
INSERT INTO takes VALUES ('12345', 'HIS-351', '1', 'Spring', '2018', 'B');
INSERT INTO advisor VALUES ('54321', '32343');
INSERT INTO advisor VALUES ('55739', '76543');
SELECT id, "name", teachers, followed_courses_by("name") FROM student;
