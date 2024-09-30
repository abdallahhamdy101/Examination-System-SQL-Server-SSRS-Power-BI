/* Database Creation */
CREATE DATABASE System_DB ;
GO
USE System_DB ;
GO
----------------------------------------------------------------------------------------------
											/*Main Tables*/
-- Create USRS table with constraints
CREATE TABLE USRS
(
    Usr_ID INT PRIMARY KEY IDENTITY,
    Usr_Fname VARCHAR(50) NOT NULL,
    Usr_Mname VARCHAR(50) NOT NULL,
    Usr_Lname VARCHAR(50) NOT NULL,
    Usr_Email VARCHAR(100) UNIQUE NOT NULL,
    Usr_Pass VARBINARY(256),  -- Store the hashed/encrypted password as binary data
    Usr_Phone VARCHAR(11) UNIQUE NOT NULL,
    Usr_DOB DATE NOT NULL,
    Usr_Age AS DATEDIFF(YEAR, Usr_DOB, GETDATE()),  -- Computed column for age
    Usr_City VARCHAR(50) NOT NULL,
    Usr_GOV VARCHAR(50) NOT NULL,
    Usr_Facebook VARCHAR(200) UNIQUE NOT NULL,
    Usr_LinkedIn VARCHAR(200) UNIQUE NOT NULL,
    Usr_Role VARCHAR(1) NOT NULL,
    Usr_Gender VARCHAR(1) NOT NULL,
    Usr_SSN VARCHAR(14) UNIQUE NOT NULL,

    -- Constraints
    CONSTRAINT CHK_Usr_Email CHECK (
        Usr_Email LIKE '%@gmail.com' OR
        Usr_Email LIKE '%@yahoo.com' OR
        Usr_Email LIKE '%@hotmail.com' OR
        Usr_Email LIKE '%@outlook.com' OR
        Usr_Email LIKE '%@aol.com' OR
        Usr_Email LIKE '%@protonmail.com'
    ),
    CONSTRAINT CHK_Usr_Pass CHECK (
        DATALENGTH(Usr_Pass) >= 8
    ),
    CONSTRAINT CHK_Usr_Phone CHECK (
        LEN(Usr_Phone) = 11 AND 
        (Usr_Phone LIKE '010%' OR 
         Usr_Phone LIKE '011%' OR 
         Usr_Phone LIKE '012%' OR 
         Usr_Phone LIKE '015%') AND
        Usr_Phone NOT LIKE '%[^0-9]%'  -- Ensure phone number contains only digits
    ),
    CONSTRAINT CHK_Usr_DOB CHECK (
        Usr_DOB <= '2002-12-31'
    ),
    CONSTRAINT CHK_Usr_Facebook CHECK (
        Usr_Facebook LIKE '%facebook%'
    ),
    CONSTRAINT CHK_Usr_LinkedIn CHECK (
        Usr_LinkedIn LIKE '%linkedin%'
    ),
    CONSTRAINT CHK_Usr_Role CHECK (
        Usr_Role IN ('I', 'S')AND
		LEN(Usr_Role) = 1
    ),
    CONSTRAINT CHK_Usr_Gender CHECK (
        Usr_Gender IN ('F', 'M')AND
		LEN(Usr_Gender) = 1
    ),
    CONSTRAINT CHK_Usr_SSN CHECK (
        LEN(Usr_SSN) = 14 AND
        Usr_SSN NOT LIKE '%[^0-9]%'  -- Ensure SSN contains only digits
    )
);

GO

----------------------------------------------------------------------------------------------
/* 2- INSTRUCTORS TABLE */
-- Create INSTRUCTORS table with a CHECK constraint
CREATE TABLE INSTRUCTORS 
(
	Ins_Usr_ID INT PRIMARY KEY ,
	Ins_Salary MONEY NOT NULL CHECK (Ins_Salary > 0),  -- Constraint for salary to be positive
	FOREIGN KEY (Ins_Usr_ID) REFERENCES USRS(Usr_ID) 
	ON DELETE CASCADE
);
GO

----------------------------------------------------------------------------------------------
/* 3- INSTRUCTOR_QUALIFICATION */
GO
CREATE TABLE INSTRUCTOR_QUALIFICATIONS 
(
    Ins_Usr_ID INT,
    Ins_Qualification VARCHAR(100) NOT NULL, 
    PRIMARY KEY (Ins_Usr_ID, Ins_Qualification),
    FOREIGN KEY (Ins_Usr_ID) REFERENCES INSTRUCTORS(Ins_Usr_ID)
	ON DELETE CASCADE
);
----------------------------------------------------------------------------------------------
/* 4- TOPICS Table */
GO
CREATE TABLE TOPICS
(
	Topic_ID INT PRIMARY KEY IDENTITY,
	Topic_Name VARCHAR(100) UNIQUE NOT NULL 
);

----------------------------------------------------------------------------------------------
/* 5- COURSES TABLE */
GO
-- Create COURSES table with a CHECK constraint for duration
CREATE TABLE COURSES
(
    Crs_ID INT PRIMARY KEY IDENTITY,
    Crs_Name VARCHAR(100) UNIQUE NOT NULL,
    Crs_Duration INT NOT NULL CHECK (Crs_Duration > 0),  -- Constraint to ensure duration is positive
    Topic_ID INT, 
    FOREIGN KEY (Topic_ID) REFERENCES TOPICS(Topic_ID)
	ON DELETE CASCADE
);
GO


----------------------------------------------------------------------------------------------
/* 6- INSTRUCTOR_COURSES */

CREATE TABLE INSTRUCTOR_COURSES
(
    Ins_Usr_ID INT,
    Crs_ID INT,
    PRIMARY KEY (Ins_Usr_ID, Crs_ID),
    FOREIGN KEY (Ins_Usr_ID) REFERENCES INSTRUCTORS(Ins_Usr_ID)
	ON DELETE CASCADE ,
    FOREIGN KEY (Crs_ID) REFERENCES COURSES(Crs_ID)
	ON DELETE CASCADE
);
GO
---------------------------------------------------------------------------------------------
/* 7- TRACKS TABLE */

CREATE TABLE TRACKS 
(
	Track_ID INT PRIMARY KEY IDENTITY, 
	Track_Name VARCHAR(100)  NOT NULL , 
	SV_Usr_ID INT , 
	FOREIGN KEY (SV_Usr_ID) REFERENCES INSTRUCTORS(Ins_Usr_ID)
	ON DELETE SET NULL
);
GO
----------------------------------------------------------------------------------------------
/* 8- TRACKS_COURSES  */
GO
CREATE TABLE TRACKS_COURSES
(
	Track_ID INT , 
	Crs_ID INT ,
	PRIMARY KEY (Track_ID , Crs_ID) ,
	FOREIGN KEY (Track_ID) REFERENCES TRACKS(Track_ID)
	ON DELETE CASCADE ,
	FOREIGN KEY (Crs_ID) REFERENCES COURSES(Crs_ID)
	ON DELETE CASCADE 

);
----------------------------------------------------------------------------------------------
/* 9-BRANCHES */
GO
CREATE TABLE BRANCHES 
(
	Branch_ID INT PRIMARY KEY IDENTITY ,
	Branch_Loc VARCHAR(100) UNIQUE NOT NULL
);
----------------------------------------------------------------------------------------------
/* 10- BRANCHES_TRACKS */
GO
CREATE TABLE BRANCHES_TRACKS
(
	Branch_ID INT ,
	Track_ID INT ,
	PRIMARY KEY (Branch_ID , Track_ID),
	FOREIGN KEY (Branch_ID) REFERENCES BRANCHES(Branch_ID)
	ON DELETE CASCADE,
	FOREIGN KEY (Track_ID) REFERENCES TRACKS(Track_ID)
	ON DELETE CASCADE
);
----------------------------------------------------------------------------------------------
/* 11- QUESTIONS TAABLE */
GO 
-- Create QUESTIONS table with a CHECK constraint for Q_Type
CREATE TABLE QUESTIONS 
(
	Q_ID INT PRIMARY KEY IDENTITY,
	Q_Type INT NOT NULL CHECK (Q_Type IN (1, 2)),  -- Constraint to restrict Q_Type values
	Q_Text VARCHAR(500) NOT NULL,
	Q_CorrectAnswer VARCHAR(200) NOT NULL,
	Crs_ID INT,
	FOREIGN KEY (Crs_ID) REFERENCES COURSES(Crs_ID)
	ON DELETE CASCADE
);
GO

----------------------------------------------------------------------------------------------
/* 12- QUESTIONS_AvailableAnswers TABLE*/
CREATE TABLE QUESTIONS_AvailableAnswers
(
	Q_ID INT ,
	Q_AvailableAnswers VARCHAR(200),
	PRIMARY KEY (Q_ID , Q_AvailableAnswers),
	FOREIGN KEY (Q_ID) REFERENCES QUESTIONS(Q_ID)
	ON DELETE CASCADE
);
----------------------------------------------------------------------------------------------
/* 13- EXAMS TABLE */

CREATE TABLE EXAMS 
(
	Exam_ID INT PRIMARY KEY IDENTITY ,
	Crs_ID	INT,
	FOREIGN KEY (Crs_ID) REFERENCES COURSES(Crs_ID)
	ON DELETE CASCADE
);
----------------------------------------------------------------------------------------------
/*14- EXAM_GEN TABLE */
CREATE TABLE EXAM_GEN
(
    Exam_ID INT,
    Q_ID INT,
    PRIMARY KEY (Exam_ID, Q_ID),
    FOREIGN KEY (Exam_ID) REFERENCES EXAMS(Exam_ID)
	ON DELETE CASCADE,
    FOREIGN KEY (Q_ID) REFERENCES QUESTIONS(Q_ID)
	ON DELETE NO ACTION
);


----------------------------------------------------------------------------------------------
/* 15- STUDENTS TABLE */
CREATE TABLE STUDENTS 
(
	S_Usr_ID INT PRIMARY KEY  ,
	std_College VARCHAR(100) NOT NULL ,
	Track_ID INT,
	Branch_ID INT ,
	FOREIGN KEY (S_Usr_ID) REFERENCES USRS(Usr_ID)
	ON DELETE CASCADE,
	FOREIGN KEY (Track_ID) REFERENCES TRACKS(Track_ID)
	ON DELETE CASCADE,
	FOREIGN KEY (Branch_ID) REFERENCES BRANCHES(Branch_ID)
	ON DELETE CASCADE
);

----------------------------------------------------------------------------------------------
/* 16- STUDENT_COURSES */
CREATE TABLE STUDENT_COURSES
(
	S_Usr_ID INT ,
	Crs_ID INT,
	PRIMARY KEY (S_Usr_ID, Crs_ID),
	FOREIGN KEY (S_Usr_ID) REFERENCES STUDENTS(S_Usr_ID)
	ON DELETE CASCADE,
	FOREIGN KEY (Crs_ID) REFERENCES COURSES(Crs_ID)
	ON DELETE CASCADE

);
----------------------------------------------------------------------------------------------
/* 17- STUDENT_ANSWERS */
CREATE TABLE STUDENT_ANSWERS
(
	S_Usr_ID INT ,
	Q_ID INT ,
	Exam_ID INT , 
	Std_Answer VARCHAR(200) NOT NULL ,
	Status BIT,
	PRIMARY KEY (S_Usr_ID, Q_ID , Exam_ID),
	FOREIGN KEY (S_Usr_ID) REFERENCES STUDENTS(S_Usr_ID)
	ON DELETE NO ACTION ,
	FOREIGN KEY (Q_ID) REFERENCES QUESTIONS(Q_ID) 
	ON DELETE NO ACTION,
	FOREIGN KEY (Exam_ID) REFERENCES EXAMS(Exam_ID)
	ON DELETE CASCADE 
);

CREATE TRIGGER trg_DeleteFromStudentAnswersOnStudents
ON STUDENTS
FOR DELETE
AS
BEGIN
    -- Delete records from STUDENT_ANSWERS where S_Usr_ID matches the deleted students
    DELETE FROM STUDENT_ANSWERS
    WHERE S_Usr_ID IN (SELECT deleted.S_Usr_ID FROM deleted);
END;


CREATE TRIGGER trg_DeleteFromStudentAnswersOnQuestions
ON QUESTIONS
FOR DELETE
AS
BEGIN
    -- Delete records from STUDENT_ANSWERS where Q_ID matches the deleted questions
    DELETE FROM STUDENT_ANSWERS
    WHERE Q_ID IN (SELECT deleted.Q_ID FROM deleted);
END;


-- STATUS TRIGGER
CREATE TRIGGER trg_UpdateStatus
ON STUDENT_ANSWERS
AFTER INSERT
AS
BEGIN
    UPDATE sa
    SET Status = CASE 
                    WHEN i.Std_Answer = q.Q_CorrectAnswer THEN 1
                    ELSE 0
                  END
    FROM STUDENT_ANSWERS sa
    INNER JOIN INSERTED i 
        ON sa.S_Usr_ID = i.S_Usr_ID
        AND sa.Q_ID = i.Q_ID
        AND sa.Exam_ID = i.Exam_ID
    INNER JOIN QUESTIONS q 
        ON i.Q_ID = q.Q_ID;
END


----------------------------------------------------------------------------------------------
/* 18- CERTIFICATES TABLE */
CREATE TABLE CERTIFICATES
(
	Cer_ID	 INT PRIMARY KEY IDENTITY,
	Cer_Name VARCHAR(100) UNIQUE NOT NULL
);
----------------------------------------------------------------------------------------------
/* 19- STUDENT_CERTIFICATE TABLE  */
CREATE TABLE STUDENT_CERTIFICATES
(
	S_Usr_ID INT , 
	Cer_ID INT ,
	Cer_Date DATE NOT NULL ,
	Cer_Code VARCHAR(10) UNIQUE , 
	PRIMARY KEY (S_Usr_ID, Cer_ID),
	FOREIGN KEY (S_Usr_ID) REFERENCES STUDENTS(S_Usr_ID)
	ON DELETE CASCADE,
	FOREIGN KEY (Cer_ID) REFERENCES CERTIFICATES(Cer_ID)
	ON DELETE CASCADE
);
----------------------------------------------------------------------------------------------
/* 20- FREELANCING_JOBS TABLE */
CREATE TABLE FREELANCING_JOBS
(
	FJ_ID INT PRIMARY KEY IDENTITY,
	FJ_JobTitle VARCHAR(100) UNIQUE NOT NULL
);

----------------------------------------------------------------------------------------------
/*21- STUDENT_JOBS TABLE*/
-- Create STUDENT_JOBS table with CHECK constraints
CREATE TABLE STUDENT_JOBS
(
	S_Usr_ID INT,
	FJ_ID INT,
	FJ_Description VARCHAR(300) NOT NULL,
	FJ_Duration INT NOT NULL,
	FJ_Date DATE NOT NULL,
	FJ_Platform VARCHAR(50) NOT NULL CHECK (FJ_Platform IN ('upwork', 'mostaql', 'khamsat', 'freelancer')),  -- Constraint for platform
	FJ_Cost MONEY NOT NULL CHECK (FJ_Cost > 0),  -- Constraint for positive job cost
	FJ_PaymentMethod VARCHAR(50) NOT NULL CHECK (FJ_PaymentMethod IN ('credit', 'debit', 'easypay', 'instapay', 'paypal', 'mobilewallet')),  -- Constraint for payment method
	PRIMARY KEY (S_Usr_ID, FJ_ID),
	FOREIGN KEY (S_Usr_ID) REFERENCES STUDENTS(S_Usr_ID) ON DELETE CASCADE,
	FOREIGN KEY (FJ_ID) REFERENCES FREELANCING_JOBS(FJ_ID) ON DELETE CASCADE
);
GO
