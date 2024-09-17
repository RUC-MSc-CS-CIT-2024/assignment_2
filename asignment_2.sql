-- Question 1
CREATE FUNCTION course_count(student_id VARCHAR)
RETURNS INTEGER AS $$
DECLARE
    course_count INTEGER;
BEGIN
    SELECT COUNT(course_id)
    INTO course_count
    FROM takes
    WHERE id = student_id;
    
    RETURN course_count;
END;
$$ LANGUAGE plpgsql;

-- Question 1 - test
select course_count('12345');
select id,course_count(id) from student;

-- Question 2
CREATE FUNCTION course_count_2(student_id VARCHAR, deptname VARCHAR)
RETURNS INTEGER AS $$
DECLARE
    course_count INTEGER;
BEGIN
    SELECT COUNT(t.course_id)
    INTO course_count
    FROM takes t
    NATURAL JOIN course c
    WHERE t.id = student_id
    AND c.dept_name = deptname;
    
    RETURN course_count;
END;
$$ LANGUAGE plpgsql;

-- Question 2 - test
SELECT course_count_2('12345', 'Comp. Sci.');

-- Question 3
-- Explanation : By using function overloading, you maintain a single function name (course_count) while providing different functionalities based on the number of arguments passed.
CREATE OR REPLACE FUNCTION course_count(student_id VARCHAR, deptname VARCHAR)
RETURNS INTEGER AS $$
DECLARE
    course_count INTEGER;
BEGIN
    SELECT COUNT(t.course_id)
    INTO course_count
    FROM takes t
    NATURAL JOIN course c
    WHERE t.id = student_id
    AND c.dept_name = deptname;
    
    RETURN course_count;
END;
$$ LANGUAGE plpgsql;

-- Question 3 -- test
SELECT course_count('45678');
SELECT course_count('45678', 'Comp. Sci.');

-- Question 4
CREATE FUNCTION department_activities(department_name VARCHAR)
RETURNS TABLE (
    instructor_name VARCHAR,
    course_title VARCHAR,
    semester VARCHAR,
    year INT
) AS
$$
BEGIN
    RETURN QUERY
    SELECT 
        i.name AS instructor_name, 
        c.title AS course_title, 
        s.semester, 
        CAST(s.year AS INT) AS year
    FROM instructor i
    NATURAL JOIN teaches t
    NATURAL JOIN section s
    NATURAL JOIN course c
    WHERE i.dept_name = department_name;
END;
$$ LANGUAGE plpgsql;

-- Question 4 -- test
SELECT department_activities('Comp. Sci.');

-- Question 5
CREATE FUNCTION activities(input_name VARCHAR)
RETURNS TABLE (
		department_name VARCHAR,
    instructor_name VARCHAR,
    course_title VARCHAR,
    semester VARCHAR,
    year INT
) AS
$$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM department d
        WHERE d.dept_name = input_name
    ) THEN
        RETURN QUERY
        SELECT 
            d.dept_name, 
            i.name AS instructor_name, 
            c.title AS course_title, 
            s.semester, 
            CAST(s.year AS INT) AS year
        FROM instructor i
        NATURAL JOIN teaches t
        NATURAL JOIN section s
        NATURAL JOIN course c
        NATURAL JOIN department d
        WHERE d.dept_name = input_name;

    ELSIF EXISTS (
        SELECT 1
        FROM department d
        WHERE d.building = input_name
    ) THEN
        RETURN QUERY
        SELECT 
            d.dept_name, 
            i.name AS instructor_name, 
            c.title AS course_title, 
            s.semester, 
            CAST(s.year AS INT) AS year
        FROM instructor i
        NATURAL JOIN teaches t
        NATURAL JOIN section s
        NATURAL JOIN course c
        NATURAL JOIN department d
        WHERE d.building = input_name;
    ELSE
        RAISE EXCEPTION 'No matching department or building found for the input: %', input_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Question 5 -- test
SELECT activities('Comp. Sci.');
SELECT activities('Watson');

-- Question 6
CREATE FUNCTION followed_courses_by(student_name VARCHAR)
RETURNS VARCHAR AS
$$
DECLARE
    result VARCHAR := '';
    next_instructor VARCHAR;
    cur CURSOR FOR 
        SELECT DISTINCT i.name
        FROM student s
        JOIN takes t USING (id)
        JOIN teaches te USING (course_id, sec_id)
        JOIN instructor i ON te.ID = i.ID
        WHERE s.name = student_name;
BEGIN
    OPEN cur;
    LOOP
        FETCH cur INTO next_instructor;
        EXIT WHEN NOT FOUND;
        IF result <> '' THEN
            result := result || ', ';
        END IF;
        result := result || next_instructor;
    END LOOP;

    CLOSE cur;

    RETURN COALESCE(result, 'No courses followed by this student or no instructors found');
END;
$$ LANGUAGE plpgsql;

-- Question 6 -- test
SELECT followed_courses_by('Levy');


-- Question 7
CREATE OR REPLACE FUNCTION followed_courses_by(student_name VARCHAR)
RETURNS VARCHAR AS
$$
DECLARE
    result VARCHAR := '';
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT DISTINCT i.name
        FROM student s
        JOIN takes t USING (id)
        JOIN teaches te USING (course_id, sec_id)
        JOIN instructor i ON te.ID = i.ID
        WHERE s.name = student_name
    LOOP
        IF result <> '' THEN
            result := result || ', ';
        END IF;
        result := result || rec.name;
    END LOOP;

    RETURN COALESCE(result, 'No courses followed by this student or no instructors found');
END;
$$ LANGUAGE plpgsql;


-- Question 7 -- test
SELECT followed_courses_by('Shankar');
SELECT name, followed_courses_by(name) FROM student;

-- Question 8
CREATE FUNCTION followed_courses_by(student_name VARCHAR)
RETURNS VARCHAR AS $$
DECLARE
    result VARCHAR := '';
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT DISTINCT i.name
        FROM student s
        JOIN takes t USING (id)
        JOIN teaches te USING (course_id, sec_id)
        JOIN instructor i ON te.ID = i.ID
        WHERE s.name = student_name
    LOOP
        IF result <> '' THEN
            result := result || ', ';
        END IF;
        result := result || rec.name;
    END LOOP;

    RETURN COALESCE(result, 'No courses followed by this student or no instructors found');
END;
$$ LANGUAGE plpgsql;

-- Question 8 -- test
SELECT followed_courses_by('Shankar');
SELECT name, followed_courses_by(name) FROM student;


-- Question 9
CREATE FUNCTION taught_by(student_name VARCHAR)
RETURNS VARCHAR AS
$$
DECLARE
    result VARCHAR := ''; 
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT DISTINCT i.name
        FROM student s
        JOIN takes t ON s.id = t.id
        JOIN teaches te ON t.course_id = te.course_id AND t.sec_id = te.sec_id
        JOIN instructor i ON te.ID = i.ID
        WHERE s.name = student_name
        
        UNION
        
        SELECT DISTINCT i.name
        FROM student s
        JOIN advisor a ON s.id = a.s_id
        JOIN instructor i ON a.i_id = i.ID
        WHERE s.name = student_name
   LOOP
        IF result <> '' THEN
            result := result || ', ';
        END IF;
        result := result || rec.name;
    END LOOP;
    RETURN COALESCE(result, 'No instructors found for this student');
END;
$$ LANGUAGE plpgsql;


-- Question 9 -- test
select taught_by('Shankar');
select name, taught_by(name) from student;

-- Question 10
ALTER TABLE student ADD COLUMN teachers TEXT;

UPDATE student s
SET teachers = (
    SELECT STRING_AGG(t.name, ', ')
    FROM advisor a
    JOIN instructor t ON a.i_id = t.id
    WHERE a.s_id = s.id
);

CREATE FUNCTION update_teachers_after_takes_insert()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE student
    SET teachers = (
        SELECT STRING_AGG(t.name, ', ')
        FROM advisor a
        JOIN instructor t ON a.i_id = t.id
        WHERE a.s_id = student.id
    )
    WHERE id = NEW.student_id;
    RETURN NEW;
END;
$$
 LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_teachers_after_advisor_insert()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE student
    SET teachers = (
        SELECT STRING_AGG(t.name, ', ')
        FROM advisor a
        JOIN instructor t ON a.i_id = t.id
        WHERE a.s_id = student.id
    )
    WHERE id = NEW.s_id;
    RETURN NEW;
END;
$$
 LANGUAGE plpgsql;

CREATE TRIGGER trg_update_teachers_after_takes_insert
AFTER INSERT ON takes
FOR EACH ROW
EXECUTE FUNCTION update_teachers_after_takes_insert();

CREATE TRIGGER trg_update_teachers_after_advisor_insert
AFTER INSERT ON advisor
FOR EACH ROW
EXECUTE FUNCTION update_teachers_after_advisor_insert();

-- Question 10 -- test
select id, name,teachers,followed_courses_by(name) from student;
insert into takes values ('12345', 'BIO-101', '1', 'Summer', '2017', 'A');
insert into takes values ('12345', 'HIS-351', '1', 'Spring', '2018', 'B');
insert into advisor values ('54321', '32343');
insert into advisor values ('55739', '76543');
select id, name,teachers,followed_courses_by(name) from student;
