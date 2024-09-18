-- CIT ASSIGNMENT 02

-- Question (1).

CREATE OR REPLACE FUNCTION course_count(student_id VARCHAR(10))
RETURNS INT AS $$
DECLARE
  return_value INT;
BEGIN
  SELECT COUNT(course_id) INTO return_value
  FROM takes
  WHERE id = student_id;
  RETURN return_value;
END;
$$ LANGUAGE plpgsql;


-- TEST QUERIES FOR QUESTION (1).
-- SELECT course_count('12345');
-- SELECT id,course_count(id) FROM student;
-- CLEAN UP AFTER QUERIES.
drop function if exists course_count(student_id VARCHAR(10));


-- Question (2).

CREATE OR REPLACE FUNCTION course_count_2(student_id VARCHAR(10), department VARCHAR(20))
RETURNS INT AS $$
DECLARE
  return_value INT;
BEGIN
  SELECT COUNT(course_id) INTO return_value
  FROM takes t
  NATURAL JOIN course c
  WHERE id = student_id AND dept_name = department;
  RETURN return_value;
END;
$$ LANGUAGE plpgsql;


-- TEST QUERIES FOR QUESTION (2).
-- SELECT course_count_2('12345','Comp. Sci.');
-- SELECT id,name,course_count_2(id,'Comp. Sci.') FROM student;
-- CLEAN UP AFTER QUERIES.
drop function if exists course_count_2(student_id VARCHAR(10), department VARCHAR(20));


-- Question (3).

CREATE OR REPLACE FUNCTION course_c(student_id VARCHAR(10), department VARCHAR(20) DEFAULT NULL)
RETURNS INT AS $$
DECLARE
  return_value INT;
BEGIN
  IF department IS NOT NULL THEN
    -- If department is provided, filter by it
    SELECT COUNT(course_id) INTO return_value
    FROM takes t
    NATURAL JOIN course c
    WHERE t.id = student_id AND c.dept_name = department;
  ELSE
    -- If no department is provided, do not filter by department
    SELECT COUNT(course_id) INTO return_value
    FROM takes t
    NATURAL JOIN course c
    WHERE t.id = student_id;
  END IF;
  
  RETURN return_value;
END;
$$ LANGUAGE plpgsql;


-- TEST QUERIES FOR QUESTION (3).
-- SELECT course_c('12345','Comp. Sci.');
-- SELECT course_c('12345');
-- SELECT id,name,course_c(id,'Comp. Sci.') FROM student;
-- CLEAN UP AFTER QUERIES.
drop function if exists course_c(student_id VARCHAR(10), department VARCHAR(20));


-- Question (4).

CREATE OR REPLACE FUNCTION department_activities(department VARCHAR(20))
RETURNS TABLE (
  instructor_name VARCHAR(50),
  course_title VARCHAR(50),
  semester VARCHAR(10),
  year INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT i.name, c.title, s.semester, s.year::INT
  FROM instructor i
  NATURAL JOIN course c 
  JOIN section s ON c.course_id = s.course_id
  WHERE c.dept_name = department;
END;
$$ LANGUAGE plpgsql;


-- TEST QUERIES FOR QUESTION (4). 
-- SELECT department_activities('Comp. Sci.');
-- CLEAN UP AFTER QUERIES.
drop function if exists department_activities(department VARCHAR(20));


-- Question (5).
-- More simpler version, but there is a chance that it could return two result sets if let's say we have a department name that is the excatly same as the building name.

CREATE OR REPLACE FUNCTION activities(param VARCHAR(20))
RETURNS TABLE (
  department_name VARCHAR(50),
  instructor_name VARCHAR(50),
  course_title VARCHAR(50),
  semester VARCHAR(10),
  year INT
) AS $$
BEGIN
  -- Check if param matches a department name
  RETURN QUERY
  SELECT d.dept_name, i.name, c.title, s.semester, s.year::INT
  FROM instructor i
  NATURAL JOIN course c
  JOIN section s ON c.course_id = s.course_id
  JOIN department d ON c.dept_name = d.dept_name
  WHERE d.dept_name = param;

  -- If no department match, check if it matches a building
  RETURN QUERY
  SELECT d.dept_name, i.name, c.title, s.semester, s.year::INT
  FROM instructor i
  NATURAL JOIN course c
  JOIN section s ON c.course_id = s.course_id
  JOIN department d ON c.dept_name = d.dept_name
  WHERE d.building = param;
  
END;
$$ LANGUAGE plpgsql;

-- TEST QUERIES FOR QUESTION (5).
-- SELECT * FROM activities('Comp. Sci.');
-- SELECT * FROM activities('Watson');
-- CLEAN UP AFTER QUERIES.
drop function if exists activities(param VARCHAR(20));

-- This is an alternative version where we are checking if the input matches department first then building, this way we are prioritizing department over building, we are then returning the first result set if the department is existing and is a match then we skip the building. Essentially only one query will be executed and returned. So no risk of a double result set.

CREATE OR REPLACE FUNCTION alternative_activities(param TEXT)
RETURNS TABLE (
  department_name VARCHAR(50),
  instructor_name VARCHAR(50),
  course_title VARCHAR(50),
  semester VARCHAR(10),
  year INT
) AS $$
DECLARE
  is_department BOOLEAN;
  is_building BOOLEAN;
BEGIN
  -- Check if param matches a department name
  SELECT EXISTS 
  (SELECT 1 FROM department WHERE dept_name = param) 
  INTO is_department;
  
  -- If it matches a department, return department-based results
  IF is_department THEN
    RETURN QUERY
    SELECT d.dept_name, i.name, c.title, s.semester, s.year::INT
    FROM instructor i
    NATURAL JOIN course c
    JOIN section s ON c.course_id = s.course_id
    JOIN department d ON c.dept_name = d.dept_name
    WHERE d.dept_name = param;
    
  -- If not a department, check if it's a building and return building-based results
  ELSE
    SELECT EXISTS 
    (SELECT 1 FROM department WHERE building = param) 
    INTO is_building;
    
    IF is_building THEN
      RETURN QUERY
      SELECT d.dept_name, i.name, c.title, s.semester, s.year::INT
      FROM instructor i
      NATURAL JOIN course c
      JOIN section s ON c.course_id = s.course_id
      JOIN department d ON c.dept_name = d.dept_name
      WHERE d.building = param;
    END IF;
  END IF;
  
END;
$$ LANGUAGE plpgsql;


-- TEST QUERIES FOR QUESTION (5). 
-- SELECT * FROM alternative_activities('Comp. Sci.');
-- SELECT * FROM alternative_activities('Watson');
-- CLEAN UP AFTER QUERIES.
drop function if exists alternative_activities(param TEXT);


-- Question (6).

CREATE OR REPLACE FUNCTION followed_course_by(student_name VARCHAR(10))
RETURNS VARCHAR(100) AS $$
DECLARE
  teacher_cursor CURSOR FOR
  SELECT DISTINCT i.name 
  FROM instructor i
  JOIN teaches u ON i.id = u.id
  JOIN takes t ON u.course_id = t.course_id
      AND u.sec_id = t.sec_id
      AND u.semester = t.semester
      AND u.year = t.year
  JOIN student s ON t.id = s.id
  WHERE s.name = student_name;
  
  return_value VARCHAR(100) := '';
  next_instructor VARCHAR(100);
BEGIN
  OPEN teacher_cursor;
  
  LOOP
    FETCH NEXT FROM teacher_cursor INTO next_instructor;
    EXIT WHEN NOT FOUND;
    
    -- Concatenate the names into a comma-separated list
    IF return_value = '' THEN
      return_value := next_instructor;  -- First value, no comma
    ELSE
      return_value := return_value || ', ' || next_instructor;
    END IF;
  END LOOP;

  CLOSE teacher_cursor;

  -- Return the final concatenated string
  RETURN return_value;
END;
$$ LANGUAGE plpgsql;


-- TEST QUERIES FOR QUESTION (6). 
-- SELECT followed_course_by('Levy');
-- CLEAN UP AFTER QUERIES.
drop function if exists followed_course_by(student_name VARCHAR(10));



-- Question (7).
-- no solution yet

-- TEST QUERIES FOR QUESTION (7). 
-- SELECT followed_course_by('Levy');

-- Question (8).

CREATE OR REPLACE FUNCTION followed_course_by_agg(student_name VARCHAR(10))
RETURNS VARCHAR AS $$
DECLARE
  return_value VARCHAR(100);
BEGIN
  -- Use STRING_AGG to concatenate the instructor names into a comma-separated list
  SELECT STRING_AGG(DISTINCT i.name, ', ')
  INTO return_value
  FROM instructor i
  JOIN teaches u ON i.id = u.id
  JOIN takes t ON u.course_id = t.course_id
      AND u.sec_id = t.sec_id
      AND u.semester = t.semester
      AND u.year = t.year
  JOIN student s ON t.id = s.id
  WHERE s.name = student_name;

  -- Return the final concatenated string
  RETURN return_value;
END;
$$ LANGUAGE plpgsql;

-- TEST QUERIES FOR QUESTION (8). 
-- SELECT followed_course_by_agg('Levy');
-- CLEAN UP AFTER QUERIES.
drop function if exists followed_course_by_agg(student_name VARCHAR(10));


-- Question (9).
-- no solution yet

-- TEST QUERIES FOR QUESTION (9). 


-- Question (10).
-- no solution yet

-- TEST QUERIES FOR QUESTION (10). 


