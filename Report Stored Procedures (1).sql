/*
•	Report that returns the students information according to Department No parameter.
*/
CREATE PROCEDURE GetStudentsByBranchLocations
    @Branch_LOCs NVARCHAR(MAX)  -- Comma-separated list of Branch_LOC values
AS
BEGIN
    -- Declare a table variable to store Branch IDs
    DECLARE @BranchIDs TABLE (Branch_ID INT);

    -- Insert the corresponding Branch_IDs for the provided Branch_LOCs
    INSERT INTO @BranchIDs (Branch_ID)
    SELECT Branch_ID
    FROM BRANCHES
    WHERE LTRIM(RTRIM(Branch_LOC)) IN (
        SELECT LTRIM(RTRIM(value))
        FROM STRING_SPLIT(@Branch_LOCs, ',')
    );

    -- Check if any Branch_IDs were found
    IF EXISTS (SELECT 1 FROM @BranchIDs)
    BEGIN
        -- Retrieve student information for the specified Branch_IDs
        SELECT  
            B.Branch_LOC,
			U.Usr_ID,
			CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS StudentName,
			U.Usr_Gender, U.Usr_Age , U.Usr_DOB , U.Usr_City , U.Usr_GOV , U.Usr_SSN 
        FROM USRS U
        INNER JOIN STUDENTS S
            ON U.Usr_ID = S.S_Usr_ID
        INNER JOIN BRANCHES B
            ON B.Branch_ID = S.Branch_ID
        WHERE B.Branch_ID IN (SELECT Branch_ID FROM @BranchIDs);
    END
    ELSE
    BEGIN
        -- If no branches were found, print a message
        PRINT 'No matching branches found for the provided locations.';
    END
END;
---------------------------------------------------------------------------------------------------------
/*
•	Report that takes the student ID and returns the grades of the student in all courses. %
*/
create proc st_grade_all_Courses @st_id int
as

BEGIN
  	

	SELECT u.Usr_Fname,c.Crs_Name,sc.grade FROM USRS U 
	INNER JOIN STUDENTS S
		ON U.Usr_ID = S.S_Usr_ID 
	INNER JOIN STUDENT_COURSES sc 
		on sc.S_Usr_ID=u.Usr_ID
	inner join COURSES c 
		on c.Crs_ID=sc.Crs_ID
	where sc.S_Usr_ID=@st_id
end
----------------------------------------------
-------------•	Report that takes the instructor ID 
----and returns the name of the courses that he teaches and the number of student per course
create proc st_and_courses_per_instructor @ins_id int
as
begin
select c.Crs_Name,count(sc.S_Usr_ID) as no_of_students
from INSTRUCTORS i 
	inner join INSTRUCTOR_COURSES ic
		on i.Ins_Usr_ID=ic.Ins_Usr_ID
	inner join COURSES c
		on c.Crs_ID=ic.Crs_ID
	inner join STUDENT_COURSES sc
		on sc.Crs_ID= ic.Crs_ID
where i.Ins_Usr_ID=@ins_id
group by c.Crs_Name

		
end
----------------------------------
•	-----Report that takes course ID and returns its topics  
create proc topic_by_course @crs_id int
as
begin
select c.Crs_Name,t.Topic_Name
from COURSES c
	inner join TOPICS t
	on t.Topic_ID=c.Topic_ID
where c.Crs_ID=@crs_id
end
--------------------------------------------------------
----------Report that takes exam number and returns the Questions in it and chocies 
create proc exam_quesion_choices @exam_id int
as
begin
select eg.Q_ID,qa.Q_AvailableAnswers as choices
from EXAM_GEN eg
	inner join QUESTIONS q
		on eg.Q_ID=q.Q_ID
	inner join QUESTIONS_AvailableAnswers qa
		on qa.Q_ID=q.Q_ID
where eg.Exam_ID=@exam_id
end
---------------------------------------------------------------------
--------------•	Report that takes exam number and the student ID 
----then returns the Questions in this exam with the student answers. 
create proc q_exam_student_answers @exam_id int ,@st_id int
as
begin

select sa.Std_Answer,q.Q_Text
from STUDENT_ANSWERS sa 
	 inner join QUESTIONS q
		on sa.Q_ID=q.Q_ID
where sa.S_Usr_ID=@st_id and sa.Exam_ID=@exam_id
end