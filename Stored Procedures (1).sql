/*
AddNewUser Procedure:
- Inserts a new user into the `USRS` table with details such as name, email, password (hashed), and role.
- Checks if the user already exists based on email or SSN. If so, it prints a message and exits.
- Depending on the role (`I` for Instructor or `S` for Student), inserts additional data into either the `INSTRUCTORS` or `STUDENTS` table (e.g., salary for instructors, college for students).
- Includes error handling with a `TRY...CATCH` block to manage and display any errors.
*/
CREATE PROCEDURE AddNewUser
    @Usr_Fname       VARCHAR(50),
    @Usr_Mname       VARCHAR(50),
    @Usr_Lname       VARCHAR(50),
    @Usr_Email       VARCHAR(100),
    @Usr_Pass        VARCHAR(256),  -- Accepts password as plain text to be hashed
    @Usr_Phone       VARCHAR(11),
    @Usr_DOB         DATE,
    @Usr_City        VARCHAR(50),
    @Usr_GOV         VARCHAR(50),
    @Usr_Facebook    VARCHAR(200),
    @Usr_LinkedIn    VARCHAR(200),
    @Usr_Role        VARCHAR(1),    -- 'I' for Instructor, 'S' for Student
    @Usr_Gender      VARCHAR(1),
    @Usr_SSN         VARCHAR(14),
    @Salary          MONEY = NULL,  -- Optional for Instructors
    @College         VARCHAR(100) = NULL -- Optional for Students
AS
BEGIN
    -- Start a transaction to ensure atomic operations
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Clean and standardize Email and SSN inputs
        SET @Usr_Email = REPLACE(LTRIM(RTRIM(@Usr_Email)), ' ', '');
        SET @Usr_SSN = REPLACE(LTRIM(RTRIM(@Usr_SSN)), ' ', '');

        -- Check if the user already exists by Email or SSN
        IF EXISTS (
            SELECT 1 
            FROM [System_Users].[USRS] 
            WHERE REPLACE(LTRIM(RTRIM(Usr_Email)), ' ', '') = @Usr_Email 
               OR REPLACE(LTRIM(RTRIM(Usr_SSN)), ' ', '') = @Usr_SSN
        )
        BEGIN
            PRINT 'User already exists.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Hash the password using SHA-256
        DECLARE @HashedPass VARBINARY(256);
        SET @HashedPass = HASHBYTES('SHA2_256', @Usr_Pass);

        -- Insert new user into the USRS table
        INSERT INTO [System_Users].[USRS] (
            Usr_Fname, Usr_Mname, Usr_Lname, Usr_Email, Usr_Pass, Usr_Phone, Usr_DOB,
            Usr_City, Usr_GOV, Usr_Facebook, Usr_LinkedIn, Usr_Role, Usr_Gender, Usr_SSN
        )
        VALUES (
            @Usr_Fname, @Usr_Mname, @Usr_Lname, @Usr_Email, @HashedPass, @Usr_Phone, @Usr_DOB,
            @Usr_City, @Usr_GOV, @Usr_Facebook, @Usr_LinkedIn, @Usr_Role, @Usr_Gender, @Usr_SSN
        );

        -- Retrieve the newly inserted User ID
        DECLARE @NewUserID INT;
        SET @NewUserID = SCOPE_IDENTITY();

        -- Conditionally insert into INSTRUCTORS or STUDENTS table based on the role
        IF @Usr_Role = 'I'  -- Instructor role
        BEGIN
            INSERT INTO [System_Users].[INSTRUCTORS] (Ins_Usr_ID, Ins_Salary)
            VALUES (@NewUserID, @Salary);
        END
        ELSE IF @Usr_Role = 'S'  -- Student role
        BEGIN
            INSERT INTO [System_Users].[STUDENTS] (S_Usr_ID, std_College)
            VALUES (@NewUserID, @College);
        END

        -- Success message
        PRINT 'User has been added successfully.';

        -- Commit the transaction if everything is successful
        COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        -- Error handling: rollback the transaction and display the error message
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), 
                @ErrorSeverity INT, 
                @ErrorState INT;

        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;

--------------------------------------------------------------------------------------------------------
/*
EditUser Procedure:
- Updates user details in the `USRS` table based on the provided `Usr_ID` and optional parameters.
- Checks if the user exists before proceeding with updates.
- Only updates fields that are provided using the `COALESCE` function, leaving other fields unchanged.
- For users with the role of Instructor, it updates the `INSTRUCTORS` table if the salary is provided.
- For users with the role of Student, it updates the `STUDENTS` table if the college is provided.
- Includes error handling with `TRY...CATCH` to manage and display errors.
*/
CREATE PROCEDURE EditUser
    @Usr_ID INT,  -- Required parameter to identify the record to update
    @Usr_Fname VARCHAR(50) = NULL,
    @Usr_Mname VARCHAR(50) = NULL,
    @Usr_Lname VARCHAR(50) = NULL,
    @Usr_Email VARCHAR(100) = NULL,
    @Usr_Pass VARCHAR(256) = NULL,  -- Password will be hashed inside the procedure
    @Usr_Phone VARCHAR(11) = NULL,
    @Usr_DOB DATE = NULL,
    @Usr_City VARCHAR(50) = NULL,
    @Usr_GOV VARCHAR(50) = NULL,
    @Usr_Facebook VARCHAR(200) = NULL,
    @Usr_LinkedIn VARCHAR(200) = NULL,
    @Usr_Role VARCHAR(1) = NULL,
    @Usr_Gender VARCHAR(1) = NULL,
    @Usr_SSN VARCHAR(14) = NULL,
    @Salary MONEY = NULL,  -- Optional parameter for Instructor salary
    @College VARCHAR(100) = NULL  -- Optional parameter for Student college
AS
BEGIN
    -- Start a transaction to ensure atomicity
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Check if the user exists in the USRS table
        IF NOT EXISTS (SELECT 1 FROM [System_Users].[USRS] WHERE Usr_ID = @Usr_ID)
        BEGIN
            PRINT 'User does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Update the USRS table, only updating columns where values are provided
        UPDATE [System_Users].[USRS]
        SET
            Usr_Fname = COALESCE(@Usr_Fname, Usr_Fname),
            Usr_Mname = COALESCE(@Usr_Mname, Usr_Mname),
            Usr_Lname = COALESCE(@Usr_Lname, Usr_Lname),
            Usr_Email = COALESCE(@Usr_Email, Usr_Email),
            Usr_Pass = COALESCE(
                CASE 
                    WHEN @Usr_Pass IS NOT NULL THEN HASHBYTES('SHA2_256', @Usr_Pass)
                    ELSE Usr_Pass 
                END, 
                Usr_Pass
            ),
            Usr_Phone = COALESCE(@Usr_Phone, Usr_Phone),
            Usr_DOB = COALESCE(@Usr_DOB, Usr_DOB),
            Usr_City = COALESCE(@Usr_City, Usr_City),
            Usr_GOV = COALESCE(@Usr_GOV, Usr_GOV),
            Usr_Facebook = COALESCE(@Usr_Facebook, Usr_Facebook),
            Usr_LinkedIn = COALESCE(@Usr_LinkedIn, Usr_LinkedIn),
            Usr_Role = COALESCE(@Usr_Role, Usr_Role),
            Usr_Gender = COALESCE(@Usr_Gender, Usr_Gender),
            Usr_SSN = COALESCE(@Usr_SSN, Usr_SSN)
        WHERE Usr_ID = @Usr_ID;

        -- If the user is an Instructor, update their salary in the INSTRUCTORS table
        IF EXISTS (SELECT 1 FROM [System_Users].[INSTRUCTORS] WHERE Ins_Usr_ID = @Usr_ID)
        BEGIN
            UPDATE [System_Users].[INSTRUCTORS]
            SET
                Ins_Salary = COALESCE(@Salary, Ins_Salary)
            WHERE Ins_Usr_ID = @Usr_ID;
        END

        -- If the user is a Student, update their college in the STUDENTS table
        IF EXISTS (SELECT 1 FROM [System_Users].[STUDENTS] WHERE S_Usr_ID = @Usr_ID)
        BEGIN
            UPDATE [System_Users].[STUDENTS]
            SET
                std_College = COALESCE(@College, std_College)
            WHERE S_Usr_ID = @Usr_ID;
        END

        -- Success message
        PRINT 'User has been updated successfully.';

        -- Commit the transaction
        COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        -- Error handling: rollback the transaction and display the error
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), 
                @ErrorSeverity INT, 
                @ErrorState INT;

        -- Capture error details
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print and raise the error
        PRINT 'Error occurred: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
--------------------------------------------------------------------------------------------------------
/*
RemoveUser Procedure:
- Deletes user records from the `USRS` table based on the provided `Usr_IDs`, which is a comma-separated list of user IDs.
- If a list of IDs is provided, the procedure splits it into individual IDs and deletes only those users.
- If no ID list is provided, all users are deleted from the `USRS` table.
- Includes a check to verify if the user IDs exist before attempting deletion.
- Handles errors using `TRY...CATCH` and provides appropriate success or error messages.
*/

CREATE PROCEDURE RemoveUser
    @Usr_IDs NVARCHAR(MAX) = NULL  -- Comma-separated list of IDs or NULL for all users
AS
BEGIN
    -- Begin transaction to ensure atomicity
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim and remove spaces from the list of user IDs if provided
        SET @Usr_IDs = REPLACE(LTRIM(RTRIM(@Usr_IDs)), ' ', '');

        -- Check if any user IDs were provided
        IF @Usr_IDs IS NOT NULL
        BEGIN
            -- Create a temporary table to store the parsed IDs
            DECLARE @IDTable TABLE (Usr_ID INT);

            -- Insert the parsed IDs into the temporary table
            INSERT INTO @IDTable (Usr_ID)
            SELECT value FROM STRING_SPLIT(@Usr_IDs, ',');

            -- Check if any of the provided IDs exist in the USRS table
            IF EXISTS (SELECT 1 FROM [System_Users].[USRS] WHERE Usr_ID IN (SELECT Usr_ID FROM @IDTable))
            BEGIN
                -- Delete users with the provided IDs from the USRS table
                DELETE FROM [System_Users].[USRS]
                WHERE Usr_ID IN (SELECT Usr_ID FROM @IDTable);

                -- Success message for deletion
                PRINT 'User/s deleted successfully.';
            END
            ELSE
            BEGIN
                -- Handle case where no matching user IDs were found
                PRINT 'User IDs do not exist.';
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END
        ELSE
        BEGIN
            -- If no user IDs were provided, delete all users
            DELETE FROM [System_Users].[USRS];
            PRINT 'All users deleted successfully.';
        END

        -- Commit the transaction after successful deletion
        COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        -- Rollback the transaction in case of an error
        ROLLBACK TRANSACTION;

        -- Capture and print the error details
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message and raise the error
        PRINT 'Error occurred: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;

--------------------------------------------------------------------------------------------------------
/*
GetUserInfo Procedure:
- This procedure retrieves user information based on one or multiple user IDs, or displays all users if no IDs are provided.
- If specific IDs are passed, it checks for their existence and returns detailed information, including instructor salary and student college, track, and branch.
- If no IDs are passed, it retrieves all users' information.
- The procedure includes error handling using TRY...CATCH and appropriate success/error messages.
- It checks for user existence and displays a relevant message if the user is not found.
*/

CREATE PROCEDURE GetUserInfo
    @Usr_IDs NVARCHAR(MAX) = NULL  -- Comma-separated list of IDs or NULL for all users
AS
BEGIN
    -- Begin transaction to ensure atomicity
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim spaces from the provided list of user IDs
        SET @Usr_IDs = REPLACE(LTRIM(RTRIM(@Usr_IDs)), ' ', '');

        -- Check if any user IDs were provided
        IF @Usr_IDs IS NOT NULL
        BEGIN
            -- Create a temporary table to store the parsed user IDs
            DECLARE @IDTable TABLE (Usr_ID INT);

            -- Insert the parsed IDs into the temporary table
            INSERT INTO @IDTable (Usr_ID)
            SELECT value FROM STRING_SPLIT(@Usr_IDs, ',');

            -- Check if the IDs exist in the USRS table
            IF NOT EXISTS (SELECT 1 FROM [System_Users].[USRS] WHERE Usr_ID IN (SELECT Usr_ID FROM @IDTable))
            BEGIN
                PRINT 'User IDs do not exist.';
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        -- Retrieve user information based on provided IDs or for all users if no IDs are provided
        SELECT
            U.Usr_ID,
            U.Usr_Fname,
            U.Usr_Mname,
            U.Usr_Lname,
            U.Usr_Email,
            U.Usr_Phone,
            U.Usr_DOB,
            U.Usr_City,
            U.Usr_GOV,
            U.Usr_Facebook,
            U.Usr_LinkedIn,
            U.Usr_Role,
            U.Usr_Gender,
            U.Usr_SSN,
            I.Ins_Salary,  -- Instructor-specific info
            S.std_College,  -- Student-specific info
            S.Track_ID, T.Track_Name,  -- Track details
            S.Branch_ID, B.Branch_Loc  -- Branch details
        FROM 
            [System_Users].[USRS] U
            LEFT JOIN [System_Users].[INSTRUCTORS] I ON U.Usr_ID = I.Ins_Usr_ID
            LEFT JOIN [System_Users].[STUDENTS] S ON U.Usr_ID = S.S_Usr_ID
            LEFT JOIN [Branches].[TRACKS] T ON S.Track_ID = T.Track_ID
            LEFT JOIN [Branches].[BRANCHES] B ON B.Branch_ID = S.Branch_ID
        WHERE
            @Usr_IDs IS NULL  -- If no IDs provided, retrieve all users
            OR U.Usr_ID IN (SELECT Usr_ID FROM @IDTable);  -- Filter by provided IDs

        -- Success message after data retrieval
        PRINT 'User information retrieved successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors and rollback transaction
        ROLLBACK TRANSACTION;

        -- Capture and print error details
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message and raise the error
        PRINT 'Error occurred: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
AuthenticateUser Procedure:
- This procedure verifies a user's authentication by taking an email and password as input.
- It hashes the provided password and compares it with the stored hashed password for the email in the database.
- If the email exists and the passwords match, the user is authenticated, and the output parameter is set to true (1).
- If the email does not exist or the passwords don't match, appropriate messages are printed.
- Error handling is implemented using TRY...CATCH to handle any exceptions during the process.
*/
CREATE PROCEDURE AuthenticateUser
    @Email VARCHAR(100),
    @Password VARCHAR(256),  -- Input plain text password to be hashed
    @IsAuthenticated BIT OUTPUT  -- Output parameter indicating authentication result
AS
BEGIN
    -- Begin the transaction to ensure atomicity
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim email input to remove extra spaces
        SET @Email = LTRIM(RTRIM(@Email));
        
        -- Declare variables for storing the hashed password
        DECLARE @StoredPassword VARBINARY(256);
        DECLARE @HashedInputPassword VARBINARY(256);

        -- Set the output parameter to false by default (unauthenticated)
        SET @IsAuthenticated = 0;

        -- Retrieve the stored hashed password for the given email
        SELECT @StoredPassword = Usr_Pass
        FROM [System_Users].[USRS]
        WHERE LTRIM(RTRIM(Usr_Email)) = @Email;

        -- Check if the email exists
        IF @StoredPassword IS NOT NULL
        BEGIN
            PRINT 'User exists, verifying password.';

            -- Hash the provided password using SHA2_256
            SET @HashedInputPassword = HASHBYTES('SHA2_256', @Password);

            -- Compare the hashed input password with the stored password
            IF @StoredPassword = @HashedInputPassword
            BEGIN
                -- Successful authentication
                SET @IsAuthenticated = 1;
                PRINT 'Authentication successful.';
            END
            ELSE
            BEGIN
                -- Password mismatch
                PRINT 'Authentication failed: Incorrect password.';
            END
        END
        ELSE
        BEGIN
            -- Email does not exist in the database
            PRINT 'Authentication failed: Email does not exist.';
        END

        -- Commit the transaction if everything is successful
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback in case of any error
        ROLLBACK TRANSACTION;

        -- Capture and print the error details
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;

--------------------------------------------------------------------------------------------------------
/*
AddInstructorNewQualification Procedure:
- This procedure inserts a qualification for an instructor by taking the instructor's user ID and qualification as input.
- It checks if the instructor exists before inserting the qualification.
- If the user exists, the qualification is inserted, and a success message is printed.
- If the user does not exist, it prints an error message.
- Error handling is implemented using TRY...CATCH to manage any exceptions during the process.
*/
CREATE PROCEDURE AddInstructorNewQualification
    @Ins_Usr_ID INT,
    @Ins_Qualification VARCHAR(100)
AS
BEGIN
    -- Start transaction for atomicity
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim whitespace from the qualification input
        SET @Ins_Qualification = LTRIM(RTRIM(@Ins_Qualification));

        -- Check if the instructor exists in the INSTRUCTORS table
        IF EXISTS (SELECT 1 FROM [System_Users].[INSTRUCTORS] WHERE Ins_Usr_ID = @Ins_Usr_ID)
        BEGIN
            PRINT 'Instructor exists, inserting qualification.';

            -- Insert the qualification into the INSTRUCTOR_QUALIFICATIONS table
            INSERT INTO [Instructors].[INSTRUCTOR_QUALIFICATIONS] (Ins_Usr_ID, Ins_Qualification)
            VALUES (@Ins_Usr_ID, @Ins_Qualification);

            PRINT 'Qualification inserted successfully.';
        END
        ELSE
        BEGIN
            -- Instructor does not exist, rollback transaction
            PRINT 'Instructor does not exist, qualification not inserted.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Commit the transaction after successful insertion
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback in case of any errors
        ROLLBACK TRANSACTION;

        -- Capture error details
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print the error message and rethrow the error
        PRINT 'Error occurred: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;

--------------------------------------------------------------------------------------------------------
/*
EditInstructorQualification Procedure:
- This procedure updates an existing qualification for an instructor.
- It takes the instructor's user ID, the old qualification, and the new qualification as input.
- It first checks if the instructor exists and if the old qualification exists for that instructor.
- If the instructor and old qualification exist, it updates the qualification.
- If the instructor exists but the old qualification does not, it inserts the new qualification and prints a message.
- If the instructor does not exist, it prints an error message.
- Error handling is implemented using TRY...CATCH to manage any exceptions during the process.
*/
CREATE PROCEDURE EditInstructorQualification
    @Ins_Usr_ID INT,
    @Old_Qualification VARCHAR(100),
    @New_Qualification VARCHAR(100)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim any unnecessary spaces from input
        SET @New_Qualification = LTRIM(RTRIM(@New_Qualification));
        SET @Old_Qualification = LTRIM(RTRIM(@Old_Qualification));

        -- Check if the instructor exists
        IF EXISTS (SELECT 1 FROM [System_Users].[INSTRUCTORS] WHERE Ins_Usr_ID = @Ins_Usr_ID)
        BEGIN
            -- Check if the old qualification exists for the instructor
            IF EXISTS (SELECT 1 FROM [Instructors].[INSTRUCTOR_QUALIFICATIONS] 
                       WHERE Ins_Usr_ID = @Ins_Usr_ID 
                         AND REPLACE(LTRIM(RTRIM(Ins_Qualification)), ' ', '') = REPLACE(@Old_Qualification, ' ', ''))
            BEGIN
                -- Update the qualification
                UPDATE [Instructors].[INSTRUCTOR_QUALIFICATIONS]
                SET Ins_Qualification = @New_Qualification
                WHERE Ins_Usr_ID = @Ins_Usr_ID
                AND REPLACE(LTRIM(RTRIM(Ins_Qualification)), ' ', '') = REPLACE(@Old_Qualification, ' ', '');

                PRINT 'Qualification updated successfully.';
            END
            ELSE
            BEGIN
                -- Old qualification does not exist, insert the new qualification
                INSERT INTO [Instructors].[INSTRUCTOR_QUALIFICATIONS] (Ins_Usr_ID, Ins_Qualification)
                VALUES (@Ins_Usr_ID, @New_Qualification);

                PRINT 'Old qualification not found. New qualification inserted.';
            END
        END
        ELSE
        BEGIN
            -- Instructor does not exist
            PRINT 'Instructor does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Commit transaction if everything succeeds
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction in case of errors
        ROLLBACK TRANSACTION;

        -- Handle errors and rethrow them
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
RemoveInstructorQualification Procedure:
- This procedure deletes a specific qualification for an instructor.
- It takes the instructor's user ID and the qualification to be deleted as input.
- It first checks if the instructor exists.
- If the instructor exists, it attempts to delete the specified qualification.
- If the qualification does not exist for the given instructor, it prints a message indicating that the qualification was not found.
- If the instructor does not exist, it prints a message indicating that the instructor was not found.
- Error handling is implemented using TRY...CATCH to manage any exceptions during the process.
*/
CREATE PROCEDURE RemoveInstructorQualification
    @Ins_Usr_ID INT,
    @Ins_Qualification VARCHAR(100)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim any unnecessary spaces from the qualification input
        SET @Ins_Qualification = LTRIM(RTRIM(@Ins_Qualification));

        -- Check if the instructor exists
        IF EXISTS (SELECT 1 FROM [System_Users].[INSTRUCTORS] WHERE Ins_Usr_ID = @Ins_Usr_ID)
        BEGIN
            -- Check if the qualification exists for the instructor
            IF EXISTS (SELECT 1 FROM [Instructors].[INSTRUCTOR_QUALIFICATIONS] 
                       WHERE Ins_Usr_ID = @Ins_Usr_ID 
                         AND REPLACE(LTRIM(RTRIM(Ins_Qualification)), ' ', '') = REPLACE(@Ins_Qualification, ' ', ''))
            BEGIN
                -- Delete the qualification
                DELETE FROM [Instructors].[INSTRUCTOR_QUALIFICATIONS]
                WHERE Ins_Usr_ID = @Ins_Usr_ID
                AND REPLACE(LTRIM(RTRIM(Ins_Qualification)), ' ', '') = REPLACE(@Ins_Qualification, ' ', '');

                PRINT 'Qualification deleted successfully.';
            END
            ELSE
            BEGIN
                -- Qualification not found for the instructor
                PRINT 'Qualification not found for this instructor.';
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END
        ELSE
        BEGIN
            -- Instructor does not exist
            PRINT 'Instructor does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Commit transaction if everything succeeds
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction in case of errors
        ROLLBACK TRANSACTION;

        -- Handle errors and rethrow them
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;

--------------------------------------------------------------------------------------------------------
/*
GetInstructorQualifications Procedure:
- This procedure retrieves the qualifications for one or more instructors.
- It takes a comma-separated list of instructor IDs as input.
- It first checks if the provided instructor IDs exist in the USRS table.
- If valid IDs are provided, it retrieves qualifications for those instructors.
- If none of the provided instructor IDs exist, it prints a message indicating that no valid IDs were found.
- If no IDs are provided, it retrieves all qualifications for all instructors.
- Error handling is implemented using TRY...CATCH to manage any exceptions during the process.
*/

CREATE PROCEDURE GetInstructorQualifications
    @Usr_IDs NVARCHAR(MAX) = NULL  -- Accepts one or more IDs as a comma-separated string
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Remove leading/trailing spaces and ensure there are no spaces between IDs
        SET @Usr_IDs = REPLACE(LTRIM(RTRIM(@Usr_IDs)), ' ', '');

        -- Check if any specific IDs were provided
        IF @Usr_IDs IS NOT NULL AND LEN(@Usr_IDs) > 0
        BEGIN
            -- Declare a temporary table to store the IDs
            DECLARE @IDTable TABLE (Usr_ID INT);

            -- Insert the IDs into the temporary table by splitting the comma-separated string
            INSERT INTO @IDTable (Usr_ID)
            SELECT CAST(value AS INT)
            FROM STRING_SPLIT(@Usr_IDs, ',')
            WHERE ISNUMERIC(value) = 1;  -- Ensure only numeric IDs are processed

            -- Select valid IDs that exist in the USRS table
            DECLARE @ValidIDs TABLE (Usr_ID INT);
            INSERT INTO @ValidIDs (Usr_ID)
            SELECT Usr_ID 
            FROM [System_Users].[USRS]
            WHERE Usr_ID IN (SELECT Usr_ID FROM @IDTable);

            -- Check if any valid IDs were found
            IF EXISTS (SELECT 1 FROM @ValidIDs)
            BEGIN
                -- Select and return qualifications for the valid IDs
                SELECT IQ.Ins_Usr_ID, IQ.Ins_Qualification
                FROM [Instructors].[INSTRUCTOR_QUALIFICATIONS] IQ
                INNER JOIN @ValidIDs V ON IQ.Ins_Usr_ID = V.Usr_ID;

                PRINT 'Qualifications displayed successfully for specified instructors.';
            END
            ELSE
            BEGIN
                -- No valid instructor IDs found
                PRINT 'No valid instructor IDs found.';
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END
        ELSE
        BEGIN
            -- No IDs provided, return all qualifications
            SELECT Ins_Usr_ID, Ins_Qualification
            FROM [Instructors].[INSTRUCTOR_QUALIFICATIONS];

            PRINT 'Qualifications of all instructors displayed successfully.';
        END

        -- Commit transaction after successful execution
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback transaction on error
        ROLLBACK TRANSACTION;

        -- Handle and rethrow the error
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;


---------------------------------------------------------------------------------------------------------
/*
AddNewTopic Procedure:
- This procedure inserts a new topic into the TOPICS table.
- It takes the name of the new topic as input, with leading and trailing spaces removed.
- Before inserting, it checks if the topic already exists in the TOPICS table, considering leading and trailing spaces.
- If the topic exists, it prints a message indicating that the topic already exists.
- If the topic does not exist, it inserts the topic and prints a confirmation message.
- Error handling is implemented using TRY...CATCH to manage any exceptions during the process.
*/
CREATE PROCEDURE AddNewTopic
    @Topic_Name VARCHAR(100)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim leading/trailing spaces from the topic name
        SET @Topic_Name = LTRIM(RTRIM(@Topic_Name));

        -- Check if the topic already exists, considering trimmed spaces
        IF EXISTS (
            SELECT 1 
            FROM [Courses].[TOPICS] 
            WHERE REPLACE(LTRIM(RTRIM(Topic_Name)), ' ', '') = REPLACE(@Topic_Name, ' ', '')
        )
        BEGIN
            PRINT 'Topic already exists.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insert the new topic into the table
        INSERT INTO [Courses].[TOPICS] (Topic_Name)
        VALUES (@Topic_Name);

        PRINT 'Topic inserted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback transaction on error
        ROLLBACK TRANSACTION;

        -- Handle and rethrow the error
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
EditTopic Procedure:
- This procedure updates the name of an existing topic or inserts a new topic if it doesn't already exist.
- It takes the current name of the topic and the new name for the topic.
- The procedure checks if a topic with the given name exists.
- If the topic exists, it prints the topic's ID, updates the topic with the new name, and prints a success message.
- If the topic doesn't exist, it prints a message indicating that the topic doesn't exist, then inserts the new topic and prints an insertion message.
- Error handling is implemented using TRY...CATCH to manage any exceptions during the process.
*/
CREATE PROCEDURE EditTopic
    @Old_Topic_Name VARCHAR(100),
    @New_Topic_Name VARCHAR(100)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim leading/trailing spaces
        SET @Old_Topic_Name = LTRIM(RTRIM(@Old_Topic_Name));
        SET @New_Topic_Name = LTRIM(RTRIM(@New_Topic_Name));
        
        -- Check if the topic with the given old name exists
        IF EXISTS (
            SELECT 1 
            FROM [Courses].[TOPICS] 
            WHERE REPLACE(LTRIM(RTRIM(Topic_Name)), ' ', '') = REPLACE(@Old_Topic_Name, ' ', '')
        )
        BEGIN
            -- Get the ID of the topic to be updated
            DECLARE @Topic_ID INT;
            SELECT @Topic_ID = Topic_ID 
            FROM [Courses].[TOPICS] 
            WHERE REPLACE(LTRIM(RTRIM(Topic_Name)), ' ', '') = REPLACE(@Old_Topic_Name, ' ', '');

            -- Update the topic with the new name
            UPDATE [Courses].[TOPICS]
            SET Topic_Name = @New_Topic_Name
            WHERE Topic_ID = @Topic_ID;

            PRINT 'Topic updated successfully.';
        END
        ELSE
        BEGIN
            -- Topic with the given old name does not exist, insert the new topic
            PRINT 'Topic with name ' + @Old_Topic_Name + ' does not exist. Inserting new topic.';

            INSERT INTO [Courses].[TOPICS] (Topic_Name)
            VALUES (@New_Topic_Name);

            PRINT 'New topic inserted successfully.';
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
RemoveTopic Procedure:
- This procedure takes the name of a topic to delete.
- It searches for the topic by name.
- If the topic exists, it retrieves its ID, prints that the topic exists, and then deletes it.
- If the topic does not exist, it prints a message indicating that the topic does not exist.
- Error handling is implemented using TRY...CATCH to manage any exceptions during the process.
*/
CREATE PROCEDURE RemoveTopic
    @Topic_Name VARCHAR(100)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim and normalize topic name for comparison
        SET @Topic_Name = LTRIM(RTRIM(@Topic_Name));

        -- Check if the topic with the given name exists
        IF EXISTS (
            SELECT Topic_ID 
            FROM [Courses].[TOPICS] 
            WHERE REPLACE(LTRIM(RTRIM(Topic_Name)), ' ', '') = REPLACE(@Topic_Name, ' ', '')
        )
        BEGIN
            -- Get the ID of the topic to be deleted
            DECLARE @Topic_ID INT;
            SELECT @Topic_ID = Topic_ID 
            FROM [Courses].[TOPICS] 
            WHERE REPLACE(LTRIM(RTRIM(Topic_Name)), ' ', '') = REPLACE(@Topic_Name, ' ', '');

            -- Delete the topic
            DELETE FROM [Courses].[TOPICS]
            WHERE Topic_ID = @Topic_ID;

            PRINT 'Topic deleted successfully.';
        END
        ELSE
        BEGIN
            -- Topic with the given name does not exist
            PRINT 'Topic with name ' + @Topic_Name + ' does not exist.';
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
GetTopic Procedure:
- This procedure takes one or multiple topic names as a comma-separated string.
- If topic names are provided, it searches for these topics, retrieves their IDs, and displays them.
- If no topic names are provided, it displays all topics.
- If a topic name does not exist, it prints a message indicating that the topic does not exist.
- Error handling is implemented using TRY...CATCH to manage any exceptions during the process.
*/
CREATE PROCEDURE GetTopic
    @Topic_Names NVARCHAR(MAX) = NULL  -- Accepts one or more topic names as a comma-separated string
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim leading and trailing spaces from the topic names
        SET @Topic_Names = LTRIM(RTRIM(@Topic_Names));

        IF @Topic_Names IS NOT NULL
        BEGIN
            -- Split the comma-separated list into a table
            DECLARE @NameTable TABLE (Topic_Name VARCHAR(100));

            -- Insert the names into the temporary table
            INSERT INTO @NameTable (Topic_Name)
            SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@Topic_Names, ',');

            -- Check if any of the provided topic names exist
            IF EXISTS (
                SELECT 1 
                FROM [Courses].[TOPICS] 
                WHERE REPLACE(LTRIM(RTRIM(Topic_Name)), ' ', '') IN (
                    SELECT REPLACE(Topic_Name, ' ', '') 
                    FROM @NameTable
                )
            )
            BEGIN
                -- Select topics for the specified names
                SELECT Topic_ID, Topic_Name
                FROM [Courses].[TOPICS]
                WHERE REPLACE(LTRIM(RTRIM(Topic_Name)), ' ', '') IN (
                    SELECT REPLACE(Topic_Name, ' ', '') 
                    FROM @NameTable
                );
                
                PRINT 'Topics displayed successfully.';
            END
            ELSE
            BEGIN
                -- No topics found for the provided names
                PRINT 'No topics found for the provided names.';
            END
        END
        ELSE
        BEGIN
            -- Select all topics if no names are provided
            SELECT Topic_ID, Topic_Name FROM [Courses].[TOPICS];
            
            PRINT 'All topics displayed successfully.';
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
--------------------------------------------------------------------------------------------------------
/*
AddNewCourse Procedure:
- This procedure takes the course name, duration, and topic ID.
- It first checks if a course with the provided name already exists.
- If the course exists, it prints a message indicating that the course already exists.
- If the course does not exist, it inserts the new course into the `COURSES` table and prints a successful insertion message.
- Error handling is implemented using TRY...CATCH to manage any exceptions during the process.
*/
CREATE PROCEDURE AddNewCourse
    @Crs_Name VARCHAR(100),
    @Crs_Duration INT,
    @Topic_Name VARCHAR(100)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim leading and trailing spaces from input parameters
        SET @Crs_Name = LTRIM(RTRIM(@Crs_Name));
        SET @Topic_Name = LTRIM(RTRIM(@Topic_Name));

        -- Check if the course already exists
        IF EXISTS (
            SELECT 1 
            FROM [Courses].[COURSES] 
            WHERE REPLACE(LTRIM(RTRIM(Crs_Name)), ' ', '') = REPLACE(@Crs_Name, ' ', '')
        )
        BEGIN
            -- Print a message indicating that the course already exists
            PRINT 'Course already exists.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Retrieve the Topic ID based on the Topic Name
        DECLARE @Topic_ID INT;
        SELECT @Topic_ID = Topic_ID  
        FROM [Courses].[TOPICS]
        WHERE REPLACE(LTRIM(RTRIM(Topic_Name)), ' ', '') = REPLACE(@Topic_Name, ' ', '');

        -- Check if the topic exists
        IF @Topic_ID IS NULL
        BEGIN
            PRINT 'Topic does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insert the new course into the COURSES table
        INSERT INTO [Courses].[COURSES] (Crs_Name, Crs_Duration, Topic_ID)
        VALUES (@Crs_Name, @Crs_Duration, @Topic_ID);
        
        -- Print a message indicating successful insertion
        PRINT 'Course inserted successfully.';
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;

--------------------------------------------------------------------------------------------------------
/*
EditCourse Procedure:
- This procedure updates the details of a course identified by its old name.
- It takes the old course name, new name, duration, and topic ID as parameters.
- If a course with the provided old name exists, it retrieves its ID, updates the course details with the provided new values (if any), and prints a success message.
- If the course does not exist, it prints a message indicating that the course does not exist and inserts a new course with the provided details.
- Error handling is implemented using TRY...CATCH to manage any exceptions during the process.
*/
CREATE PROCEDURE EditCourse
    @Old_Crs_Name VARCHAR(100),  -- The current name of the course to be updated or inserted
    @New_Crs_Name VARCHAR(100) = NULL,  -- New name for the course (optional)
    @New_Crs_Duration INT = NULL,  -- New duration for the course (optional)
    @New_Topic_ID INT = NULL  -- New topic ID for the course (optional)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim leading and trailing spaces from input parameters
        SET @Old_Crs_Name = LTRIM(RTRIM(@Old_Crs_Name));
        SET @New_Crs_Name = LTRIM(RTRIM(@New_Crs_Name));

        -- Check if the course with the old name exists
        DECLARE @Course_ID INT;
        SELECT @Course_ID = Crs_ID
        FROM [Courses].[COURSES]
        WHERE REPLACE(LTRIM(RTRIM(Crs_Name)), ' ', '') = REPLACE(@Old_Crs_Name, ' ', '');

        IF @Course_ID IS NOT NULL
        BEGIN
            -- Course exists, update the course details
            UPDATE [Courses].[COURSES]
            SET 
                Crs_Name = COALESCE(@New_Crs_Name, Crs_Name),  -- If NULL, keep the current value
                Crs_Duration = COALESCE(@New_Crs_Duration, Crs_Duration),  -- If NULL, keep the current value
                Topic_ID = COALESCE(@New_Topic_ID, Topic_ID)  -- If NULL, keep the current value
            WHERE Crs_ID = @Course_ID;
            
            PRINT 'Course updated successfully.';
        END
        ELSE
        BEGIN
            -- Course does not exist, insert a new course
            IF @New_Crs_Name IS NULL OR @New_Crs_Duration IS NULL OR @New_Topic_ID IS NULL
            BEGIN
                PRINT 'Cannot insert a new course with missing details.';
                ROLLBACK TRANSACTION;
                RETURN;
            END

            -- Insert the new course into the COURSES table
            INSERT INTO [Courses].[COURSES] (Crs_Name, Crs_Duration, Topic_ID)
            VALUES (@New_Crs_Name, @New_Crs_Duration, @New_Topic_ID);
            
            PRINT 'Course did not exist. A new course has been inserted.';
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
--------------------------------------------------------------------------------------------------------
/*
RemoveCourse Procedure:
- This procedure deletes a course based on its old name.
- It takes the old course name as a parameter.
- If a course with the provided name exists, it retrieves its ID and deletes the course from the COURSES table.
- If the course does not exist, it prints a message indicating that the course was not found.
- Error handling is implemented using TRY...CATCH to manage any exceptions during the process.
*/
CREATE PROCEDURE RemoveCourse
    @Crs_Name VARCHAR(100)  -- The name of the course to be deleted
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim leading and trailing spaces from input parameter
        SET @Crs_Name = LTRIM(RTRIM(@Crs_Name));
        
        -- Check if the course with the given name exists
        DECLARE @Course_ID INT;
        SELECT @Course_ID = Crs_ID
        FROM [Courses].[COURSES]
        WHERE REPLACE(LTRIM(RTRIM(Crs_Name)), ' ', '') = REPLACE(@Crs_Name, ' ', '');

        IF @Course_ID IS NOT NULL
        BEGIN
            -- Course exists, delete it
            DELETE FROM [Courses].[COURSES]
            WHERE Crs_ID = @Course_ID;
            
            PRINT 'Course deleted successfully.';
        END
        ELSE
        BEGIN
            -- Course does not exist
            PRINT 'Course with the specified name does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;

--------------------------------------------------------------------------------------------------------
/*
GetCourses Procedure:
- This procedure selects and displays courses based on their names.
- It takes one or more course names as a comma-separated string.
- If the provided course names exist, it retrieves their IDs and then displays the corresponding course details.
- If no course names are provided, it displays all courses.
- If a course does not exist, it prints a message indicating that the course was not found.
- Error handling is implemented using TRY...CATCH to manage any exceptions during the process.
*/
CREATE PROCEDURE GetCourses
    @Crs_Names NVARCHAR(MAX) = NULL  -- Accepts one or more course names as a comma-separated string
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim leading and trailing spaces from the input parameter
        SET @Crs_Names = REPLACE(LTRIM(RTRIM(@Crs_Names)), ' ', '');

        IF @Crs_Names IS NOT NULL
        BEGIN
            -- Create a temporary table to store the course names
            DECLARE @NameTable TABLE (Crs_Name VARCHAR(100));

            -- Insert the names into the temporary table
            INSERT INTO @NameTable (Crs_Name)
            SELECT value FROM STRING_SPLIT(@Crs_Names, ',');

            -- Check if any courses match the provided names
            IF EXISTS (
                SELECT 1
                FROM [Courses].[COURSES] c
                JOIN @NameTable nt ON REPLACE(LTRIM(RTRIM(c.Crs_Name)), ' ', '') = REPLACE(nt.Crs_Name, ' ', '')
            )
            BEGIN
                -- Select courses for the provided names
                SELECT c.*
                FROM [Courses].[COURSES] c
                JOIN @NameTable nt ON REPLACE(LTRIM(RTRIM(c.Crs_Name)), ' ', '') = REPLACE(nt.Crs_Name, ' ', '');
                
                PRINT 'Courses displayed successfully.';
            END
            ELSE
            BEGIN
                -- No courses found for the provided names
                PRINT 'No courses found for the provided names.';
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END
        ELSE
        BEGIN
            -- Select all courses if no names are provided
            SELECT * FROM [Courses].[COURSES];
            
            PRINT 'All courses displayed successfully.';
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
AssignInstructorToCourse Procedure
This procedure assigns an instructor to a course. It performs the following:
1. Takes an instructor ID and a course name as input parameters.
2. Searches for the instructor ID and checks if it exists.
3. Searches for the course by name, retrieves its course ID if it exists.
4. If both the instructor and course exist, inserts the assignment into the INSTRUCTOR_COURSES table.
5. Prints relevant messages if the instructor or course does not exist.
6. Includes error handling using TRY...CATCH.
*/

CREATE PROCEDURE AssignInstructorToCourse
    @Ins_Usr_ID INT,
    @Crs_Name VARCHAR(100)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim and standardize course name
        SET @Crs_Name = LTRIM(RTRIM(@Crs_Name));
        
        DECLARE @Crs_ID INT;

        -- Retrieve the course ID based on the course name
        SELECT @Crs_ID = Crs_ID
        FROM [Courses].[COURSES]
        WHERE REPLACE(LTRIM(RTRIM(Crs_Name)), ' ', '') = REPLACE(@Crs_Name, ' ', '');

        -- Check if the course exists
        IF @Crs_ID IS NULL
        BEGIN
            PRINT 'Course "' + @Crs_Name + '" does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Check if the instructor exists
        IF EXISTS (SELECT 1 FROM [System_Users].[USRS] WHERE Usr_ID = @Ins_Usr_ID)
        BEGIN
            -- Assign instructor to the course
            INSERT INTO [Instructors].[INSTRUCTOR_COURSES] (Ins_Usr_ID, Crs_ID)
            VALUES (@Ins_Usr_ID, @Crs_ID);

            PRINT 'Instructor assigned to the course successfully.';
        END
        ELSE
        BEGIN
            PRINT 'Instructor with ID ' + CAST(@Ins_Usr_ID AS VARCHAR(10)) + ' does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
UnassignInstructorFromCourse Procedure:
- This procedure unassigns an instructor from a course based on the course name.
- It takes the instructor ID and the course name as parameters.
- The procedure first searches for the course by name to retrieve its ID.
- It also checks if the instructor exists before attempting to unassign.
- If both the course and instructor exist, it unassigns the instructor from the course and prints a success message.
- If either the course or instructor does not exist, it prints a message indicating what was not found.
- Error handling is implemented using TRY...CATCH to manage any exceptions during the process.
*/
CREATE PROCEDURE UnassignInstructorFromCourse
    @Ins_Usr_ID INT,
    @Crs_Name VARCHAR(100)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim and standardize course name
        SET @Crs_Name = LTRIM(RTRIM(@Crs_Name));
        
        -- Declare a variable to hold the course ID
        DECLARE @Crs_ID INT;

        -- Retrieve the course ID based on the course name
        SELECT @Crs_ID = Crs_ID
        FROM [Courses].[COURSES]
        WHERE REPLACE(LTRIM(RTRIM(Crs_Name)), ' ', '') = REPLACE(@Crs_Name, ' ', '');

        -- Check if the course exists
        IF @Crs_ID IS NULL
        BEGIN
            PRINT 'Course "' + @Crs_Name + '" does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Check if the instructor exists
        IF EXISTS (SELECT 1 FROM [System_Users].[USRS] WHERE Usr_ID = @Ins_Usr_ID)
        BEGIN
            -- Delete the instructor-course assignment
            DELETE FROM [Instructors].[INSTRUCTOR_COURSES]
            WHERE Ins_Usr_ID = @Ins_Usr_ID
            AND Crs_ID = @Crs_ID;

            PRINT 'Instructor unassigned from the course successfully.';
        END
        ELSE
        BEGIN
            PRINT 'Instructor with ID ' + CAST(@Ins_Usr_ID AS VARCHAR(10)) + ' does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
GetInstructorCourseDetails Procedure:
- This procedure retrieves details of instructors and their assigned courses.
- It takes a comma-separated list of instructor IDs as input.
- The procedure searches for the provided instructor IDs in the USRS and INSTRUCTORS tables.
- If any of the provided instructor IDs exist, it retrieves and displays their course details.
- If no instructor IDs are found, it prints a message indicating that the instructor IDs do not exist.
- Error handling is implemented using TRY...CATCH to manage any exceptions during the process.
*/
CREATE PROCEDURE GetInstructorCourseDetails
    @Ins_Usr_IDs NVARCHAR(MAX) = NULL  -- Comma-separated list of instructor IDs
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim and standardize instructor IDs
        SET @Ins_Usr_IDs = REPLACE(LTRIM(RTRIM(@Ins_Usr_IDs)), ' ', '');

        -- Prepare a temporary table for IDs
        DECLARE @InstructorTable TABLE (Ins_Usr_ID INT);

        -- Populate the temporary table with provided instructor IDs if not NULL
        IF @Ins_Usr_IDs IS NOT NULL
        BEGIN
            INSERT INTO @InstructorTable (Ins_Usr_ID)
            SELECT CAST(value AS INT) FROM STRING_SPLIT(@Ins_Usr_IDs, ',');
        END

        -- Retrieve instructor and course details
        SELECT  
            I.Ins_Usr_ID AS InstructorID,
            CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS InstructorName,
            IC.Crs_ID AS CourseID,
            C.Crs_Name AS CourseName
        FROM [System_Users].[USRS] U
        INNER JOIN [System_Users].[INSTRUCTORS] I ON U.Usr_ID = I.Ins_Usr_ID
        INNER JOIN [Instructors].[INSTRUCTOR_COURSES] IC ON I.Ins_Usr_ID = IC.Ins_Usr_ID
        INNER JOIN [Courses].[COURSES] C ON C.Crs_ID = IC.Crs_ID
        WHERE (@Ins_Usr_IDs IS NULL OR I.Ins_Usr_ID IN (SELECT Ins_Usr_ID FROM @InstructorTable));
        
        -- Check if any records were returned
        IF @@ROWCOUNT = 0
        BEGIN
            PRINT 'No instructors found with the provided IDs.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
GetCourseInstructorDetails Procedure:
- This procedure retrieves details of instructors and the courses they are assigned to.
- It accepts a comma-separated list of course names as input. If no names are provided, it retrieves details for all courses.
- The procedure performs the following actions:
  1. Creates a temporary table to store course IDs.
  2. Searches for the provided course names in the COURSES table and populates the temporary table with their IDs.
  3. Joins the relevant tables (`USRS`, `INSTRUCTORS`, `INSTRUCTOR_COURSES`, `COURSES`) to gather instructor and course information.
  4. Returns a result set containing the course ID, course name, instructor ID, and instructor name.
- If no course names are provided, the procedure retrieves and displays details for all courses and their assigned instructors.
- If a course name does not exist, it prints a message indicating that the course name does not exist.
*/
CREATE PROCEDURE GetCourseInstructorDetails
    @Crs_Names NVARCHAR(MAX) = NULL  -- Comma-separated list of course names
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Standardize course names input
        SET @Crs_Names = REPLACE(LTRIM(RTRIM(@Crs_Names)), ' ', '');

        -- Prepare a temporary table for course IDs
        DECLARE @CourseTable TABLE (Crs_ID INT);

        -- Populate the temporary table with course IDs
        IF @Crs_Names IS NOT NULL
        BEGIN
            INSERT INTO @CourseTable (Crs_ID)
            SELECT Crs_ID 
            FROM [Courses].[COURSES]
            WHERE REPLACE(LTRIM(RTRIM(Crs_Name)), ' ', '') IN (SELECT value FROM STRING_SPLIT(@Crs_Names, ','));

            -- Check if any course IDs were found
            IF NOT EXISTS (SELECT 1 FROM @CourseTable)
            BEGIN
                PRINT 'No courses found with the provided names.';
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        -- Retrieve instructor and course details
        SELECT  
            C.Crs_ID AS CourseID,
            C.Crs_Name AS CourseName,
            I.Ins_Usr_ID AS InstructorID,
            CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS InstructorName
        FROM [Courses].[COURSES] C
        INNER JOIN [Instructors].[INSTRUCTOR_COURSES] IC ON C.Crs_ID = IC.Crs_ID
        INNER JOIN [System_Users].[INSTRUCTORS] I ON IC.Ins_Usr_ID = I.Ins_Usr_ID
        INNER JOIN [System_Users].[USRS] U ON I.Ins_Usr_ID = U.Usr_ID
        WHERE (@Crs_Names IS NULL OR C.Crs_ID IN (SELECT Crs_ID FROM @CourseTable));

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;


---------------------------------------------------------------------------------------------------------
/*
AddNewTrack Procedure:
- This procedure inserts a new track into the TRACKS table.
- It takes the name of the track and an optional supervisor user ID as input parameters.
- The procedure performs the following actions:
  1. Checks if the track with the provided name already exists in the TRACKS table.
  2. If the track exists, prints a message indicating that the track already exists.
  3. If the track does not exist, inserts the new track into the TRACKS table and prints a successful insertion message.
- Error handling is included to manage any issues that arise during the execution of the procedure.
*/
CREATE PROCEDURE AddNewTrack
    @Track_Name VARCHAR(100),
    @SV_Usr_ID INT = NULL
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Standardize input by trimming and removing extra spaces
        SET @Track_Name = LTRIM(RTRIM(@Track_Name));

        -- Check if the track already exists
        IF EXISTS (
            SELECT 1
            FROM [Branches].[TRACKS]
            WHERE REPLACE(LTRIM(RTRIM(Track_Name)), ' ', '') = REPLACE(@Track_Name , ' ', '')
        )
        BEGIN
            PRINT 'Track already exists.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insert the new track
        INSERT INTO [Branches].[TRACKS] (Track_Name, SV_Usr_ID)
        VALUES (@Track_Name, @SV_Usr_ID);

        PRINT 'Track inserted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
EditTrack Procedure:
- This procedure updates track details based on the provided track name.
- It accepts the track name to be updated, the new track name, and an optional supervisor user ID.
- The procedure performs the following actions:
  1. Searches for the track by name in the TRACKS table.
  2. If the track exists, retrieves its ID and updates the track details with the new name and supervisor user ID.
  3. If the track does not exist, prints a message indicating that the track doesn't exist and inserts a new track with the provided details.
- Error handling is implemented using TRY...CATCH to manage and report any exceptions.
*/
CREATE PROCEDURE EditTrack
    @Track_Name VARCHAR(100),
    @New_Track_Name VARCHAR(100) = NULL,
    @SV_Usr_ID INT = NULL
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Standardize input by trimming and removing extra spaces
        SET @Track_Name = LTRIM(RTRIM(@Track_Name));
        SET @New_Track_Name = LTRIM(RTRIM(@New_Track_Name));

        -- Declare a variable to store the Track_ID
        DECLARE @Track_ID INT;

        -- Find the Track_ID for the provided Track_Name
        SELECT @Track_ID = Track_ID
        FROM [Branches].[TRACKS]
        WHERE REPLACE(LTRIM(RTRIM(Track_Name)), ' ', '') = REPLACE(@Track_Name , ' ', '');

        -- Check if the track exists
        IF @Track_ID IS NOT NULL
        BEGIN
            -- Update the track details
            UPDATE [Branches].[TRACKS]
            SET Track_Name = COALESCE(@New_Track_Name, Track_Name),
                SV_Usr_ID = COALESCE(@SV_Usr_ID, SV_Usr_ID)
            WHERE Track_ID = @Track_ID;

            PRINT 'Track updated successfully.';
        END
        ELSE
        BEGIN
            -- Print message if the track does not exist
            PRINT 'Track does not exist. Inserting new track.';

            -- Insert a new track with the provided details
            INSERT INTO [Branches].[TRACKS] (Track_Name, SV_Usr_ID)
            VALUES (COALESCE(@New_Track_Name, @Track_Name), @SV_Usr_ID);

            PRINT 'New track inserted successfully.';
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
RemoveTrack Procedure:
- This procedure deletes a track from the TRACKS table based on the provided track name.
- It accepts the track name as input.
- The procedure performs the following actions:
  1. Searches for the track by name in the TRACKS table.
  2. If the track exists, retrieves its ID and deletes the track using this ID.
  3. If the track does not exist, prints a message indicating that the track doesn't exist.
- Error handling is implemented using TRY...CATCH to manage and report any exceptions.
*/
CREATE PROCEDURE RemoveTrack
    @Track_Name VARCHAR(100)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Standardize input by trimming and removing extra spaces
        SET @Track_Name = LTRIM(RTRIM(@Track_Name));

        -- Declare a variable to store the Track_ID
        DECLARE @Track_ID INT;

        -- Find the Track_ID for the provided Track_Name
        SELECT @Track_ID = Track_ID
        FROM [Branches].[TRACKS]
        WHERE REPLACE(LTRIM(RTRIM(Track_Name)), ' ', '') = REPLACE(@Track_Name, ' ', '');

        -- Check if the track exists
        IF @Track_ID IS NOT NULL
        BEGIN
            -- Delete the track
            DELETE FROM [Branches].[TRACKS]
            WHERE Track_ID = @Track_ID;

            PRINT 'Track deleted successfully.';
        END
        ELSE
        BEGIN
            -- Print message if the track does not exist
            PRINT 'Track does not exist.';
			ROLLBACK TRANSACTION ;
			RETURN;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

--------------------------------------------------------------------------------------------------------
/*
AddNewBranch Procedure:
- This procedure inserts a new branch into the BRANCHES table based on the provided branch location.
- The procedure performs the following actions:
  1. Searches for the branch by location in the BRANCHES table.
  2. If the branch already exists, it prints a message indicating the branch exists.
  3. If the branch does not exist, it inserts the branch into the table and prints a success message.
- Error handling is implemented using TRY...CATCH to manage and report any exceptions.
*/
CREATE PROCEDURE AddNewBranch
    @Branch_Loc VARCHAR(100)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Standardize input by trimming and removing extra spaces
        SET @Branch_Loc = LTRIM(RTRIM(@Branch_Loc));

        -- Check if the branch already exists
        IF EXISTS (SELECT 1 FROM [Branches].[BRANCHES]
                   WHERE REPLACE(LTRIM(RTRIM(Branch_Loc)), ' ', '') = REPLACE(@Branch_Loc, ' ' ,'') )
        BEGIN
            PRINT 'Branch already exists.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insert the new branch
        INSERT INTO [Branches].[BRANCHES] (Branch_Loc)
        VALUES (@Branch_Loc);

        PRINT 'Branch inserted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
EditBranch Procedure:
- This procedure updates an existing branch's location or inserts it if it does not already exist.
- The procedure performs the following actions:
  1. Searches for the branch by location.
  2. If the branch exists, it retrieves the branch's ID and updates the branch location.
  3. If the branch does not exist, it inserts the branch and prints a success message.
- Error handling is implemented using TRY...CATCH to manage and report any exceptions.
*/
CREATE PROCEDURE EditBranch
    @Branch_Loc VARCHAR(100),
    @New_Branch_Loc VARCHAR(100) = NULL
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Standardize input by trimming and removing extra spaces
        SET @Branch_Loc = LTRIM(RTRIM(@Branch_Loc));
        SET @New_Branch_Loc = LTRIM(RTRIM(@New_Branch_Loc));

        -- Declare a variable to store the Branch_ID
        DECLARE @Branch_ID INT;

        -- Find the Branch_ID for the provided Branch_Loc
        SELECT @Branch_ID = Branch_ID
        FROM [Branches].[BRANCHES]
        WHERE REPLACE(LTRIM(RTRIM(Branch_Loc)), ' ', '') = REPLACE(@Branch_Loc, ' ' , '');

        -- Check if the branch exists
        IF @Branch_ID IS NOT NULL
        BEGIN
            -- Update the branch if it exists
            UPDATE [Branches].[BRANCHES]
            SET Branch_Loc = COALESCE(@New_Branch_Loc, Branch_Loc)
            WHERE Branch_ID = @Branch_ID;

            PRINT 'Branch updated successfully.';
        END
        ELSE
        BEGIN
            -- Insert the new branch if it doesn't exist
            INSERT INTO [Branches].[BRANCHES] (Branch_Loc)
            VALUES (@Branch_Loc);

            PRINT 'Branch did not exist. New branch inserted successfully.';
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
RemoveBranch Procedure:
- This procedure deletes a branch based on the provided branch location.
- The procedure performs the following actions:
  1. Searches for the branch by location.
  2. If the branch exists, it deletes the branch and prints a success message.
  3. If the branch does not exist, it prints a message indicating that the branch was not found.
- Error handling is implemented using TRY...CATCH to manage and report any exceptions.
*/
CREATE PROCEDURE RemoveBranch
    @Branch_Loc VARCHAR(100)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Standardize input by trimming and removing extra spaces
        SET @Branch_Loc = LTRIM(RTRIM(@Branch_Loc));

        -- Declare a variable to store the Branch_ID
        DECLARE @Branch_ID INT;

        -- Find the Branch_ID for the provided Branch_Loc
        SELECT @Branch_ID = Branch_ID
        FROM [Branches].[BRANCHES]
        WHERE REPLACE(LTRIM(RTRIM(Branch_Loc)), ' ', '') = REPLACE(@Branch_Loc, ' ' , '');

        -- Check if the branch exists
        IF @Branch_ID IS NOT NULL
        BEGIN
            -- Delete the branch if it exists
            DELETE FROM [Branches].[BRANCHES]
            WHERE Branch_ID = @Branch_ID;

            PRINT 'Branch deleted successfully.';
        END
        ELSE
        BEGIN
            -- Print a message if the branch does not exist
            PRINT 'Branch does not exist.';
            -- Rollback transaction as the branch does not exist
            ROLLBACK TRANSACTION;
            RETURN;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
AssignTrackToBranch Procedure:
- This procedure assigns a track to a branch based on their names.
- It accepts Branch_Loc and Track_Name as input parameters and performs the following actions:
  1. Searches for the Branch_ID based on Branch_Loc.
  2. Searches for the Track_ID based on Track_Name.
  3. If both the branch and track exist, assigns the track to the branch by inserting into the BRANCHES_TRACKS table.
  4. If either the branch or track does not exist, prints appropriate messages indicating the missing entities.
  5. Includes error handling using TRY CATCH to manage any runtime errors.
*/

CREATE PROCEDURE AssignTrackToBranch
    @Branch_Loc VARCHAR(100),
    @Track_Name VARCHAR(100)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Standardize inputs by trimming and removing extra spaces
        SET @Branch_Loc = LTRIM(RTRIM(@Branch_Loc));
        SET @Track_Name = LTRIM(RTRIM(@Track_Name));

        -- Declare variables to store IDs
        DECLARE @Branch_ID INT;
        DECLARE @Track_ID INT;

        -- Retrieve Branch_ID based on the provided Branch_Loc
        SELECT @Branch_ID = Branch_ID
        FROM [Branches].[BRANCHES]
        WHERE REPLACE(LTRIM(RTRIM(Branch_Loc)), ' ', '') = REPLACE(@Branch_Loc, ' ' , '');

        -- Retrieve Track_ID based on the provided Track_Name
        SELECT @Track_ID = Track_ID
        FROM [Branches].[TRACKS]
        WHERE REPLACE(LTRIM(RTRIM(Track_Name)), ' ', '') = REPLACE(@Track_Name, ' ','');
        
        -- Check if Branch_ID and Track_ID exist
        IF @Branch_ID IS NULL
        BEGIN
            PRINT 'Branch location "' + @Branch_Loc + '" does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        IF @Track_ID IS NULL
        BEGIN
            PRINT 'Track name "' + @Track_Name + '" does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Check if the assignment already exists
        IF EXISTS (SELECT 1 FROM [Branches].[BRANCHES_TRACKS] WHERE Branch_ID = @Branch_ID AND Track_ID = @Track_ID)
        BEGIN
            PRINT 'Track "' + @Track_Name + '" is already assigned to branch "' + @Branch_Loc + '".';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Insert the new assignment
        INSERT INTO [Branches].[BRANCHES_TRACKS] (Branch_ID, Track_ID)
        VALUES (@Branch_ID, @Track_ID);
        
        PRINT 'Track "' + @Track_Name + '" assigned to branch "' + @Branch_Loc + '" successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
UnassignTrackFromBranch :
This procedure removes the assignment of a track from a branch based on the branch location and track name. 
It performs the following steps:
1. Searches for the Branch_ID and Track_ID based on the provided Branch_Loc and Track_Name.
2. If both exist, it removes the assignment from the BRANCHES_TRACKS table.
3. If either does not exist, it prints an appropriate message.
4. Includes error handling using TRY...CATCH.
*/

CREATE PROCEDURE UnassignTrackFromBranch
    @Branch_Loc VARCHAR(100),
    @Track_Name VARCHAR(100)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Standardize inputs by trimming and removing extra spaces
        SET @Branch_Loc = LTRIM(RTRIM(@Branch_Loc));
        SET @Track_Name = LTRIM(RTRIM(@Track_Name));

        -- Declare variables to store IDs
        DECLARE @Branch_ID INT;
        DECLARE @Track_ID INT;

        -- Retrieve Branch_ID based on the provided Branch_Loc
        SELECT @Branch_ID = Branch_ID
        FROM [Branches].[BRANCHES]
        WHERE REPLACE(LTRIM(RTRIM(Branch_Loc)), ' ', '') = REPLACE(@Branch_Loc , ' ' , '');

        -- Retrieve Track_ID based on the provided Track_Name
        SELECT @Track_ID = Track_ID
        FROM [Branches].[TRACKS]
        WHERE REPLACE(LTRIM(RTRIM(Track_Name)), ' ', '') = REPLACE(@Track_Name , ' ' , '');

        -- Check if Branch_ID and Track_ID exist
        IF @Branch_ID IS NULL
        BEGIN
            PRINT 'Branch location "' + @Branch_Loc + '" does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        IF @Track_ID IS NULL
        BEGIN
            PRINT 'Track name "' + @Track_Name + '" does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Check if the assignment exists before attempting to delete
        IF NOT EXISTS (SELECT 1 FROM [Branches].[BRANCHES_TRACKS] WHERE Branch_ID = @Branch_ID AND Track_ID = @Track_ID)
        BEGIN
            PRINT 'Assignment of track "' + @Track_Name + '" to branch "' + @Branch_Loc + '" does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Delete the assignment
        DELETE FROM [Branches].[BRANCHES_TRACKS]
        WHERE Branch_ID = @Branch_ID
          AND Track_ID = @Track_ID;
        
        PRINT 'Track "' + @Track_Name + '" unassigned from branch "' + @Branch_Loc + '" successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
GetTrackInfo Procedure
This procedure retrieves information about tracks based on a list of track names. 
It performs the following actions:
1. Accepts a comma-separated list of track names as input.
2. Searches for each track name in the TRACKS table to retrieve its ID.
3. Retrieves and displays track details along with associated instructor and branch information.
4. If a track name does not exist, it prints a message indicating that the track was not found.
5. Includes error handling using TRY...CATCH.
*/
CREATE PROCEDURE GetTrackInfo
    @Track_Names NVARCHAR(MAX) = NULL  -- Comma-separated list of Track Names
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim spaces and clean up the input
        SET @Track_Names = REPLACE(LTRIM(RTRIM(@Track_Names)), ' ', '');
        
        -- Declare a temporary table to store track names and IDs
        DECLARE @TrackTable TABLE (Track_ID INT, Track_Name NVARCHAR(100));

        -- Populate the temporary table with track names
        IF @Track_Names IS NOT NULL
        BEGIN
            INSERT INTO @TrackTable (Track_Name)
            SELECT value AS Track_Name
            FROM STRING_SPLIT(@Track_Names, ',');
            
            -- Update the Track_ID for each track name in the temporary table
            UPDATE TT
            SET Track_ID = T.Track_ID
            FROM @TrackTable TT
            INNER JOIN [Branches].[TRACKS] T 
                ON REPLACE(LTRIM(RTRIM(T.Track_Name)), ' ', '') = TT.Track_Name;
        END

        -- Check if any valid tracks were found
        IF EXISTS (SELECT 1 FROM @TrackTable WHERE Track_ID IS NOT NULL)
        BEGIN
            -- Retrieve the track information along with instructor and branch details
            SELECT  T.Track_Name,
                    I.Ins_Usr_ID AS SupervisorID, 
                    CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS SupervisorName,
                    B.Branch_Loc
            FROM [System_Users].[USRS] U
            INNER JOIN [System_Users].[INSTRUCTORS] I ON U.Usr_ID = I.Ins_Usr_ID
            INNER JOIN [Branches].[TRACKS] T ON I.Ins_Usr_ID = T.SV_Usr_ID
            INNER JOIN [Branches].[BRANCHES_TRACKS] BT ON T.Track_ID = BT.Track_ID
            INNER JOIN [Branches].[BRANCHES] B ON B.Branch_ID = BT.Branch_ID
            WHERE T.Track_ID IN (SELECT Track_ID FROM @TrackTable WHERE Track_ID IS NOT NULL);
        END
        ELSE
        BEGIN
            PRINT 'No valid tracks found.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
31- GetBranchInfo Procedure
This procedure retrieves information about branches based on a list of branch names. 
It performs the following actions:
1. Accepts a comma-separated list of branch names as input.
2. Searches for each branch name in the BRANCHES table to retrieve its ID.
3. Retrieves and displays branch details along with associated tracks and instructor information.
4. If a branch name does not exist, it prints a message indicating that the branch was not found.
5. Includes error handling using TRY...CATCH.
*/
CREATE PROCEDURE GetBranchInfo
    @Branch_Names NVARCHAR(MAX) = NULL  -- Comma-separated list of Branch Names
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Clean up the input: remove spaces around the commas and trim any leading/trailing spaces
        SET @Branch_Names = REPLACE(LTRIM(RTRIM(@Branch_Names)), ' ', '');

        -- Declare a temporary table for branch names and IDs
        DECLARE @BranchTable TABLE (Branch_ID INT, Branch_Name NVARCHAR(100));

        -- Populate the temporary table with the given branch names
        IF @Branch_Names IS NOT NULL
        BEGIN
            INSERT INTO @BranchTable (Branch_Name)
            SELECT value AS Branch_Name
            FROM STRING_SPLIT(@Branch_Names, ',');
            
            -- Update the Branch_ID for each branch in the temporary table based on the cleaned branch name
            UPDATE BT
            SET BT.Branch_ID = B.Branch_ID
            FROM @BranchTable BT
            INNER JOIN [Branches].[BRANCHES] B 
                ON REPLACE(LTRIM(RTRIM(B.Branch_Loc)), ' ', '') = BT.Branch_Name;
        END

        -- Check if any valid branches were found
        IF EXISTS (SELECT 1 FROM @BranchTable WHERE Branch_ID IS NOT NULL)
        BEGIN
            -- Retrieve branch information along with track and supervisor (instructor) details
            SELECT  
                B.Branch_Loc,
                T.Track_Name,
                I.Ins_Usr_ID AS SupervisorID,
                CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS SupervisorName
            FROM [System_Users].[USRS] U
            INNER JOIN [System_Users].[INSTRUCTORS] I ON U.Usr_ID = I.Ins_Usr_ID
            INNER JOIN [Branches].[TRACKS] T ON I.Ins_Usr_ID = T.SV_Usr_ID
            INNER JOIN [Branches].[BRANCHES_TRACKS] BT ON T.Track_ID = BT.Track_ID
            INNER JOIN [Branches].[BRANCHES] B ON B.Branch_ID = BT.Branch_ID
            WHERE B.Branch_ID IN (SELECT Branch_ID FROM @BranchTable WHERE Branch_ID IS NOT NULL);
        END
        ELSE
        BEGIN
            PRINT 'No valid branches found.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle any errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print the error message and roll back the transaction
        PRINT 'Error occurred: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
32- AssignCourseToTrack Procedure
This procedure assigns a course to a track based on the track name and course name. 
It performs the following actions:
1. Accepts the track name and course name as input parameters.
2. Searches for the track by name to retrieve its ID.
3. Searches for the course by name to retrieve its ID.
4. If both the track and the course exist, it assigns the course to the track and prints a success message.
5. If either the track or the course does not exist, it prints a relevant message indicating which item was not found.
6. Includes error handling using TRY...CATCH to manage any exceptions during the process.
*/

CREATE PROCEDURE AssignCourseToTrack
    @Track_Name NVARCHAR(100),
    @Crs_Name NVARCHAR(100)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim leading and trailing spaces from the track and course names
        SET @Track_Name = LTRIM(RTRIM(@Track_Name));
        SET @Crs_Name = LTRIM(RTRIM(@Crs_Name));

        -- Declare variables to hold IDs
        DECLARE @Track_ID INT;
        DECLARE @Crs_ID INT;

        -- Search for Track_ID by name
        SELECT @Track_ID = Track_ID
        FROM [Branches].[TRACKS]
        WHERE REPLACE(LTRIM(RTRIM(Track_Name)), ' ', '') = REPLACE(@Track_Name, ' ', '');

        -- Search for Crs_ID by name
        SELECT @Crs_ID = Crs_ID
        FROM [Courses].[COURSES]
        WHERE REPLACE(LTRIM(RTRIM(Crs_Name)), ' ', '') = REPLACE(@Crs_Name, ' ', '');

        -- Check if both the track and course exist
        IF @Track_ID IS NOT NULL AND @Crs_ID IS NOT NULL
        BEGIN
            -- Check if the course is already assigned to the track to avoid duplicates
            IF NOT EXISTS (SELECT 1 FROM [Branches].[TRACKS_COURSES] WHERE Track_ID = @Track_ID AND Crs_ID = @Crs_ID)
            BEGIN
                -- Insert the course into the track
                INSERT INTO [Branches].[TRACKS_COURSES] (Track_ID, Crs_ID)
                VALUES (@Track_ID, @Crs_ID);

                PRINT 'Course "' + @Crs_Name + '" assigned to track "' + @Track_Name + '" successfully.';
            END
            ELSE
            BEGIN
                PRINT 'The course "' + @Crs_Name + '" is already assigned to the track "' + @Track_Name + '".';
            END
        END
        ELSE
        BEGIN
            -- Print messages for missing items
            IF @Track_ID IS NULL
            BEGIN
                PRINT 'Track "' + @Track_Name + '" does not exist.';
                ROLLBACK TRANSACTION;
                RETURN;
            END
            IF @Crs_ID IS NULL
            BEGIN
                PRINT 'Course "' + @Crs_Name + '" does not exist.';
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
33- UnassignCourseFromTrack Procedure
This procedure unassigns a course from a track based on the track name and course name. 
It performs the following actions:
1. Accepts the track name and course name as input parameters.
2. Searches for the track by name to retrieve its ID.
3. Searches for the course by name to retrieve its ID.
4. If both the track and the course exist, it unassigns the course from the track and prints a success message.
5. If either the track or the course does not exist, it prints a relevant message indicating which item was not found.
6. Includes error handling using TRY...CATCH to manage any exceptions during the process.
*/
CREATE PROCEDURE UnassignCourseFromTrack
    @Track_Name NVARCHAR(100),
    @Crs_Name NVARCHAR(100)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim leading and trailing spaces from the track and course names
        SET @Track_Name = LTRIM(RTRIM(@Track_Name));
        SET @Crs_Name = LTRIM(RTRIM(@Crs_Name));

        -- Declare variables to hold IDs
        DECLARE @Track_ID INT;
        DECLARE @Crs_ID INT;

        -- Search for Track_ID by name
        SELECT @Track_ID = Track_ID
        FROM [Branches].[TRACKS]
        WHERE REPLACE(LTRIM(RTRIM(Track_Name)), ' ', '') = REPLACE(@Track_Name, ' ', '');

        -- Search for Crs_ID by name
        SELECT @Crs_ID = Crs_ID
        FROM [Courses].[COURSES]
        WHERE REPLACE(LTRIM(RTRIM(Crs_Name)), ' ', '') = REPLACE(@Crs_Name, ' ', '');

        -- Check if both the track and course exist
        IF @Track_ID IS NOT NULL AND @Crs_ID IS NOT NULL
        BEGIN
            -- Check if the course is assigned to the track
            IF EXISTS (SELECT 1 FROM [Branches].[TRACKS_COURSES] WHERE Track_ID = @Track_ID AND Crs_ID = @Crs_ID)
            BEGIN
                -- Unassign the course from the track
                DELETE FROM [Branches].[TRACKS_COURSES]
                WHERE Track_ID = @Track_ID AND Crs_ID = @Crs_ID;

                PRINT 'Course "' + @Crs_Name + '" unassigned from track "' + @Track_Name + '" successfully.';
            END
            ELSE
            BEGIN
                PRINT 'Course "' + @Crs_Name + '" is not assigned to track "' + @Track_Name + '".';
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END
        ELSE
        BEGIN
            -- Print messages for missing track or course
            IF @Track_ID IS NULL
            BEGIN
                PRINT 'Track "' + @Track_Name + '" does not exist.';
                ROLLBACK TRANSACTION;
                RETURN;
            END
            IF @Crs_ID IS NULL
            BEGIN
                PRINT 'Course "' + @Crs_Name + '" does not exist.';
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
GetTrackCoursesInfo Procedure
This procedure retrieves information about tracks based on a list of track names. 
It performs the following actions:
1. Accepts a comma-separated list of track names as input.
2. Searches for each track name in the TRACKS table to retrieve its ID.
3. Retrieves and displays track details along with course and topic information.
4. If a track name does not exist, it prints a message indicating that the track was not found.
5. Includes error handling using TRY...CATCH to manage any exceptions during the process.
*/

CREATE PROCEDURE GetTrackCoursesInfo
    @Track_Names NVARCHAR(MAX) = NULL  -- Comma-separated list of Track Names
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Remove extra spaces and standardize the input
        SET @Track_Names = REPLACE(LTRIM(RTRIM(@Track_Names)), ' ', '');

        -- Declare a temporary table to hold the track names and IDs
        DECLARE @TrackTable TABLE (Track_ID INT, Track_Name NVARCHAR(100));

        -- Populate the temporary table if Track_Names is provided
        IF @Track_Names IS NOT NULL
        BEGIN
            INSERT INTO @TrackTable (Track_Name)
            SELECT value AS Track_Name
            FROM STRING_SPLIT(@Track_Names, ',');

            -- Retrieve Track_IDs for the provided Track_Names
            UPDATE @TrackTable
            SET Track_ID = T.Track_ID
            FROM @TrackTable TT
            INNER JOIN [Branches].[TRACKS] T 
                ON REPLACE(LTRIM(RTRIM(T.Track_Name)), '  ', '') = TT.Track_Name;
        END

        -- Check if any valid tracks were found
        IF EXISTS (SELECT 1 FROM @TrackTable WHERE Track_ID IS NOT NULL)
        BEGIN
            -- Retrieve detailed track, course, and topic information
            SELECT  
                T.Track_ID AS TrackID, 
                T.Track_Name AS TrackName, 
                I.Ins_Usr_ID AS SupervisorID, 
                CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS SupervisorName,
                C.Crs_ID AS CourseID, 
                C.Crs_Name AS CourseName, 
                C.Crs_Duration AS CourseDuration,
                TPC.Topic_ID AS TopicID, 
                TPC.Topic_Name AS TopicName
            FROM [System_Users].[USRS] U
            INNER JOIN [System_Users].[INSTRUCTORS] I ON U.Usr_ID = I.Ins_Usr_ID
            INNER JOIN [Branches].[TRACKS] T ON I.Ins_Usr_ID = T.SV_Usr_ID
            INNER JOIN [Branches].[TRACKS_COURSES] TC ON T.Track_ID = TC.Track_ID
            INNER JOIN [Courses].[COURSES] C ON C.Crs_ID = TC.Crs_ID
            INNER JOIN [Courses].[TOPICS] TPC ON TPC.Topic_ID = C.Topic_ID
            WHERE T.Track_ID IN (SELECT Track_ID FROM @TrackTable WHERE Track_ID IS NOT NULL);
        END
        ELSE
        BEGIN
            PRINT 'No valid tracks found.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle any errors that occur
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rollback the transaction and rethrow the error
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;

--------------------------------------------------------------------------------------------------------
/*
GetCourseTrackInfo Procedure
This procedure retrieves information about courses based on a list of course names. 
It performs the following actions:
1. Accepts a comma-separated list of course names as input.
2. Searches for each course name in the COURSES table to retrieve its ID.
3. Retrieves and displays course details along with track and instructor information.
4. If a course name does not exist, it prints a message indicating that the course was not found.
5. Includes error handling using TRY...CATCH to manage any exceptions during the process.
*/
CREATE PROCEDURE GetCourseTrackInfo
    @Crs_Names NVARCHAR(MAX) = NULL  -- Comma-separated list of Course Names
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Remove extra spaces and standardize the input
        SET @Crs_Names = REPLACE(LTRIM(RTRIM(@Crs_Names)), ' ', '');

        -- Declare a temporary table to hold course names and IDs
        DECLARE @CourseTable TABLE (Crs_ID INT, Crs_Name NVARCHAR(100));

        -- Populate the temporary table if Crs_Names is provided
        IF @Crs_Names IS NOT NULL
        BEGIN
            INSERT INTO @CourseTable (Crs_Name)
            SELECT value AS Crs_Name
            FROM STRING_SPLIT(@Crs_Names, ',');

            -- Retrieve Crs_IDs for the provided Crs_Names
            UPDATE @CourseTable
            SET Crs_ID = C.Crs_ID
            FROM @CourseTable CT
            INNER JOIN [Courses].[COURSES] C 
                ON REPLACE(LTRIM(RTRIM(C.Crs_Name)), '  ', '') = CT.Crs_Name;
        END

        -- Check if any valid courses were found
        IF EXISTS (SELECT 1 FROM @CourseTable WHERE Crs_ID IS NOT NULL)
        BEGIN
            -- Retrieve detailed course, track, and instructor information
            SELECT  
                C.Crs_ID AS CourseID, 
                C.Crs_Name AS CourseName, 
                C.Crs_Duration AS CourseDuration,
                TPC.Topic_ID AS TopicID, 
                TPC.Topic_Name AS TopicName,
                T.Track_ID AS TrackID, 
                T.Track_Name AS TrackName, 
                I.Ins_Usr_ID AS SupervisorID, 
                CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS SupervisorName
            FROM [System_Users].[USRS] U
            INNER JOIN [System_Users].[INSTRUCTORS] I ON U.Usr_ID = I.Ins_Usr_ID
            INNER JOIN [Branches].[TRACKS] T ON I.Ins_Usr_ID = T.SV_Usr_ID
            INNER JOIN [Branches].[TRACKS_COURSES] TC ON T.Track_ID = TC.Track_ID
            INNER JOIN [Courses].[COURSES] C ON C.Crs_ID = TC.Crs_ID
            INNER JOIN [Courses].[TOPICS] TPC ON TPC.Topic_ID = C.Topic_ID
            WHERE C.Crs_ID IN (SELECT Crs_ID FROM @CourseTable WHERE Crs_ID IS NOT NULL);
        END
        ELSE
        BEGIN
            PRINT 'No valid courses found.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle any errors that occur
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rollback the transaction and rethrow the error
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
AddNewQuestionWithAnswers:
The `AddNewQuestionWithAnswers` stored procedure inserts a new question and its associated available answers into the `QUESTIONS` and `QUESTIONS_AvailableAnswers` tables.
- It checks if the question already exists by comparing a trimmed and space-removed version of the question text.
- If the question already exists:
  - The procedure rolls back the transaction and exits without inserting the question.
- If the question does not exist:
  - The procedure inserts the question into the `QUESTIONS` table.
  - It retrieves the newly inserted `Q_ID`.
  - It splits the comma-separated available answers and inserts them into the `QUESTIONS_AvailableAnswers` table.
- Error handling is included to capture any issues, and the transaction ensures data integrity.*/
CREATE PROCEDURE AddNewQuestionWithAnswers
    @Q_Type INT,
    @Q_Text VARCHAR(500),
    @Q_CorrectAnswer VARCHAR(200),
    @Crs_Name VARCHAR(100),  -- Changed type to VARCHAR for course name
    @AvailableAnswers VARCHAR(MAX)  -- Comma-separated list of answers
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Clean up the input strings
        SET @Q_Text = LTRIM(RTRIM(@Q_Text));
        SET @Q_CorrectAnswer = LTRIM(RTRIM(@Q_CorrectAnswer));
        SET @AvailableAnswers = LTRIM(RTRIM(@AvailableAnswers));
        SET @Crs_Name = LTRIM(RTRIM(@Crs_Name));

        -- Check if the question already exists (ignoring spaces)
        IF EXISTS (
            SELECT 1 
            FROM [Courses].[QUESTIONS] 
            WHERE REPLACE(LTRIM(RTRIM(Q_Text)), ' ', '') = REPLACE(@Q_Text, ' ', '')
        )
        BEGIN
            -- If the question exists, inform the user and exit
            PRINT 'The Question already exists';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Check if the course exists and get the Crs_ID
        DECLARE @Crs_ID INT;
        SELECT @Crs_ID = Crs_ID
        FROM [Courses].[COURSES]
        WHERE REPLACE(LTRIM(RTRIM(Crs_Name)), ' ', '') = REPLACE(@Crs_Name, ' ', '');

        -- If the course does not exist, inform the user and exit
        IF @Crs_ID IS NULL
        BEGIN
            PRINT @Crs_Name + ' is not found';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Insert the new question
        INSERT INTO [Courses].[QUESTIONS] (Q_Type, Q_Text, Q_CorrectAnswer, Crs_ID)
        VALUES (@Q_Type, @Q_Text, @Q_CorrectAnswer, @Crs_ID);

        -- Retrieve the last inserted Q_ID
        DECLARE @Q_ID INT;
        SET @Q_ID = SCOPE_IDENTITY();

        -- Split the available answers and insert them into QUESTIONS_AvailableAnswers
        ;WITH SplitAnswers AS (
            SELECT LTRIM(RTRIM(value)) AS Q_AvailableAnswers
            FROM STRING_SPLIT(@AvailableAnswers, ',')
            WHERE LTRIM(RTRIM(value)) <> ''  -- Exclude empty values
        )
        INSERT INTO [Courses].[QUESTIONS_AvailableAnswers] (Q_ID, Q_AvailableAnswers)
        SELECT @Q_ID, Q_AvailableAnswers
        FROM SplitAnswers;

        -- Commit the transaction upon success
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors by capturing the error details
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print the error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rollback the transaction and rethrow the error
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
---------------------------------------------------------------------------------------------------------
/*
EditQuestionWithAnswers:
- Edits an existing question or inserts a new one with its available answers.
- Input Parameters: 
  - `@Q_ID`: ID of the question to edit or insert.
  - Optional parameters: `@Q_Type`, `@Q_Text`, `@Q_CorrectAnswer`, `@Crs_ID`, `@AvailableAnswers` (comma-separated).
  
- Checks if Question Exists: 
  - If the question with the provided `@Q_ID` exists, it updates the question details (if provided) and available answers (if provided).
  
- Updates Available Answers:
  - If `@AvailableAnswers` is provided, deletes the existing answers and inserts new ones (split by commas).
  
- Inserts a New Question:
  - If the question doesn't exist, it inserts a new question into the `QUESTIONS` table and retrieves the new `Q_ID`.
  - Inserts the provided available answers linked to the newly inserted question.

- Error Handling:
  - Catches errors and rolls back the transaction if any issues occur.
  - Uses a `TRY...CATCH` block for transaction management.

*/
CREATE PROCEDURE EditQuestionWithAnswers
    @Q_ID INT,
    @Q_Type INT = NULL,  -- Optional parameter
    @Q_Text VARCHAR(500) = NULL,  -- Optional parameter
    @Q_CorrectAnswer VARCHAR(200) = NULL,  -- Optional parameter
    @Crs_ID INT = NULL,  -- Optional parameter
    @AvailableAnswers VARCHAR(MAX) = NULL  -- Optional parameter
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Clean up the input strings
        SET @Q_Text = LTRIM(RTRIM(@Q_Text));
        SET @Q_CorrectAnswer = LTRIM(RTRIM(@Q_CorrectAnswer));
        SET @AvailableAnswers = LTRIM(RTRIM(@AvailableAnswers));

        -- Check if the question exists
        IF EXISTS (SELECT 1 FROM [Courses].[QUESTIONS] WHERE Q_ID = @Q_ID)
        BEGIN 
            -- Update the question if parameters are not NULL
            UPDATE [Courses].[QUESTIONS]
            SET 
                Q_Type = COALESCE(@Q_Type, Q_Type),
                Q_Text = COALESCE(@Q_Text, Q_Text),
                Q_CorrectAnswer = COALESCE(@Q_CorrectAnswer, Q_CorrectAnswer),
                Crs_ID = COALESCE(@Crs_ID, Crs_ID)
            WHERE Q_ID = @Q_ID;
                
            -- If AvailableAnswers is provided, update available answers
            IF @AvailableAnswers IS NOT NULL
            BEGIN
                -- Delete existing available answers
                DELETE FROM [Courses].[QUESTIONS_AvailableAnswers]
                WHERE Q_ID = @Q_ID;
                
                -- Split the available answers and insert them
                ;WITH SplitAnswers AS (
                    SELECT LTRIM(RTRIM(value)) AS Q_AvailableAnswers  -- Trim spaces
                    FROM STRING_SPLIT(@AvailableAnswers, ',')
                    WHERE LTRIM(RTRIM(value)) <> ''  -- Exclude empty values
                )
                INSERT INTO [Courses].[QUESTIONS_AvailableAnswers] (Q_ID, Q_AvailableAnswers)
                SELECT @Q_ID, Q_AvailableAnswers
                FROM SplitAnswers;
            END
        END
        ELSE
        BEGIN 
            PRINT 'QUESTION Not Exist, Inserting The Question...';
            
            -- Insert the question
            INSERT INTO [Courses].[QUESTIONS] (Q_Type, Q_Text, Q_CorrectAnswer, Crs_ID)
            VALUES (@Q_Type, @Q_Text, @Q_CorrectAnswer, @Crs_ID);

            -- Retrieve the last inserted Q_ID
            SET @Q_ID = SCOPE_IDENTITY();

            -- Split the available answers and insert them
            ;WITH SplitAnswers AS (
                SELECT LTRIM(RTRIM(value)) AS Q_AvailableAnswers
                FROM STRING_SPLIT(@AvailableAnswers, ',')
                WHERE LTRIM(RTRIM(value)) <> ''  -- Exclude empty values
            )
            INSERT INTO [Courses].[QUESTIONS_AvailableAnswers] (Q_ID, Q_AvailableAnswers)
            SELECT @Q_ID, Q_AvailableAnswers
            FROM SplitAnswers;            
        END

        -- Commit the transaction upon success
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors by capturing the error details
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print the error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rollback the transaction and rethrow the error
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
--------------------------------------------------------------------------------------------------------
/*
RemoveQuestion:
This stored procedure, `DeleteQuestion`, deletes a question from the `QUESTIONS` table based on the provided `Q_ID`.
- It first checks if the question exists. If found, it deletes the question and prints a success message.
- If not found, it prints a message that the question doesn't exist and rolls back the transaction.
- Error handling and transactions are implemented using TRY...CATCH blocks.
*/

CREATE PROCEDURE RemoveQuestion
    @Q_ID INT
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Check if the question exists
        IF EXISTS (SELECT 1 FROM [Courses].[QUESTIONS] WHERE Q_ID = @Q_ID)
        BEGIN            
            -- Delete the question
            DELETE FROM [Courses].[QUESTIONS] WHERE Q_ID = @Q_ID;
            PRINT 'Question deleted successfully.';
        END
        ELSE
        BEGIN
            PRINT 'Question does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
            
        PRINT 'Error occurred: ' + @ErrorMessage;
        
        -- Rethrow the error and rollback
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

--------------------------------------------------------------------------------------------------------
/*
ExamPresentation: 
- This stored procedure, `ExamPresentation`, retrieves details of an exam, including related course information, questions, and available answers.
- It first checks if the exam exists by the provided `@Exam_ID`. If the exam doesn't exist, it prints a message and rolls back the transaction.
- If the exam exists, it selects the exam details, joining data from the `COURSES`, `EXAM_GEN`, `QUESTIONS`, and `QUESTIONS_AvailableAnswers` tables. 
  The results are ordered by question type.
- Error handling is included using transactions and TRY...CATCH.
*/

CREATE PROCEDURE ExamPresentation
    @Exam_ID INT
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Check if the Exam ID exists
        IF NOT EXISTS (SELECT 1 FROM [Courses].[EXAMS] WHERE Exam_ID = @Exam_ID)
        BEGIN 
            PRINT 'EXAM Not Exists';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Select exam details along with course, question, and available answers
        SELECT E.Exam_ID, 
               C.Crs_Name,
               Q.Q_ID, 
               Q.Q_Text, 
               Q.Q_Type,
               A.Q_AvailableAnswers
        FROM [Courses].[EXAMS] E
        INNER JOIN [Courses].[COURSES] C
            ON C.Crs_ID = E.Crs_ID
        INNER JOIN [Courses].[EXAM_GEN] EG
            ON E.Exam_ID = EG.Exam_ID
        INNER JOIN [Courses].[QUESTIONS] Q
            ON Q.Q_ID = EG.Q_ID
        INNER JOIN [Courses].[QUESTIONS_AvailableAnswers] A
            ON Q.Q_ID = A.Q_ID
        WHERE E.Exam_ID = @Exam_ID
        ORDER BY Q.Q_Type DESC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;
        
        -- Rethrow the error and rollback
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;


CREATE PROCEDURE ExamGeneration
    @Crs_ID INT  -- Course ID to be inserted into EXAMS and associated with the questions
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Check if the course exists
        IF NOT EXISTS (SELECT 1 FROM [Courses].[COURSES] WHERE Crs_ID = @Crs_ID)
        BEGIN 
            PRINT 'Course Not Exists';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Declare a variable to hold the new Exam_ID
        DECLARE @NewExam_ID INT;

        -- Insert the exam record into EXAMS and get the new Exam_ID
        INSERT INTO [Courses].[EXAMS] (Crs_ID)
        VALUES (@Crs_ID);

        -- Retrieve the last inserted Exam_ID
        SET @NewExam_ID = SCOPE_IDENTITY();

        -- Insert random MCQ questions into EXAM_GEN
        ;WITH RandomMCQs AS (
            SELECT TOP 15 Q_ID
            FROM [Courses].[QUESTIONS]
            WHERE Q_Type = 1 AND Crs_ID = @Crs_ID -- MCQ type
            ORDER BY NEWID()  -- Random order
        )
        INSERT INTO [Courses].[EXAM_GEN] (Exam_ID, Q_ID)
        SELECT @NewExam_ID, Q_ID
        FROM RandomMCQs;

        -- Insert random T/F questions into EXAM_GEN
        ;WITH RandomTFs AS (
            SELECT TOP 5 Q_ID
            FROM [Courses].[QUESTIONS]
            WHERE Q_Type = 2 AND Crs_ID = @Crs_ID -- T/F type
            ORDER BY NEWID()  -- Random order
        )
        INSERT INTO [Courses].[EXAM_GEN] (Exam_ID, Q_ID)
        SELECT @NewExam_ID, Q_ID
        FROM RandomTFs;

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;

        -- Call the ExamPresentation procedure to present the exam details
        EXEC ExamPresentation @NewExam_ID;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error and rollback
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
This stored procedure assigns students to a specific track and branch based on their names and location.
It performs the following actions:
1. Checks if each student ID exists in the STUDENTS table.
2. Retrieves the ID of the specified track and branch based on their names and locations.
3. Updates the students' Track_ID and Branch_ID if all entities are found.
4. Provides relevant messages if any student ID, track, or branch is not found.
5. Includes error handling to manage any issues during the transaction.
*/
CREATE PROCEDURE AssignStudentToTrackAndBranch
    @Std_IDs VARCHAR(MAX),    -- Comma-separated list of student IDs
    @Track_Name NVARCHAR(100), -- Name of the track
    @Branch_Loc NVARCHAR(100)  -- Location of the branch
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Trim input values
        SET @Track_Name = LTRIM(RTRIM(@Track_Name));
        SET @Branch_Loc = LTRIM(RTRIM(@Branch_Loc));

        -- Declare variables for Track and Branch IDs
        DECLARE @Track_ID INT;
        DECLARE @Branch_ID INT;

        -- Retrieve Track_ID based on Track_Name
        SELECT @Track_ID = Track_ID
        FROM [Branches].[TRACKS]
        WHERE REPLACE(LTRIM(RTRIM(@Track_Name)), ' ', '') = REPLACE(@Track_Name, ' ', '');

        IF @Track_ID IS NULL
        BEGIN
            PRINT 'Track not found';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Retrieve Branch_ID based on Branch_Loc
        SELECT @Branch_ID = Branch_ID
        FROM [Branches].[BRANCHES]
        WHERE REPLACE(LTRIM(RTRIM(@Branch_Loc)), ' ', '') = REPLACE(@Branch_Loc, ' ', '');

        IF @Branch_ID IS NULL
        BEGIN
            PRINT 'Branch not found';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Create a table variable to store student IDs
        DECLARE @StudentList TABLE (
            S_Usr_ID INT
        );

        -- Insert student IDs into the table variable
        INSERT INTO @StudentList (S_Usr_ID)
        SELECT value
        FROM STRING_SPLIT(@Std_IDs, ',');

        -- Check if student IDs exist and print relevant messages
        DECLARE @StudentID INT;
        DECLARE @StudentExists BIT;

        DECLARE student_cursor CURSOR FOR
            SELECT S_Usr_ID
            FROM @StudentList;

        OPEN student_cursor;

        FETCH NEXT FROM student_cursor INTO @StudentID;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Check if student exists
            SET @StudentExists = (SELECT CASE WHEN EXISTS (SELECT 1 FROM [System_Users].[STUDENTS] WHERE S_Usr_ID = @StudentID) THEN 1 ELSE 0 END);

            IF @StudentExists = 1
            BEGIN
                -- Update the student's Track_ID and Branch_ID
                UPDATE [System_Users].[STUDENTS]
                SET Track_ID = @Track_ID,
                    Branch_ID = @Branch_ID
                WHERE S_Usr_ID = @StudentID;
				PRINT 'Student ID ' + CAST(@StudentID AS VARCHAR(10)) + ' Assigned Successfully .';
            END
            ELSE
            BEGIN
                PRINT 'Student ID ' + CAST(@StudentID AS VARCHAR(10)) + ' does not exist.';
            END

            FETCH NEXT FROM student_cursor INTO @StudentID;
        END

        CLOSE student_cursor;
        DEALLOCATE student_cursor;

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error and rollback
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
UnassignStudentFromTrackAndBranch: 
This stored procedure unassigns students from their current track and branch based on their IDs.
It performs the following actions:
1. Retrieves the track name and branch location for each student based on their current IDs.
2. Checks if each student ID exists in the STUDENTS table and prints relevant messages.
3. Updates the students' Track_ID and Branch_ID to NULL.
4. Prints messages indicating each student's unassignment, including track and branch details.
5. Includes error handling to manage any issues during the transaction.
*/

CREATE PROCEDURE UnassignStudentFromTrackAndBranch
    @Std_IDs VARCHAR(MAX)      -- Comma-separated list of student IDs
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Trim input value
        SET @Std_IDs = LTRIM(RTRIM(@Std_IDs));

        -- Declare a table variable to hold student IDs and their statuses
        DECLARE @StudentStatus TABLE (
            S_Usr_ID INT,
            Track_ID INT,
            Branch_ID INT,
            Track_Name NVARCHAR(100),
            Branch_Loc NVARCHAR(100),
            Status NVARCHAR(50)
        );

        -- Split the list of student IDs and retrieve their current Track_ID and Branch_ID
        ;WITH StudentList AS (
            SELECT value AS S_Usr_ID
            FROM STRING_SPLIT(@Std_IDs, ',')
        )
        INSERT INTO @StudentStatus (S_Usr_ID, Track_ID, Branch_ID, Track_Name, Branch_Loc, Status)
        SELECT S.S_Usr_ID,
               S.Track_ID,
               S.Branch_ID,
               T.Track_Name,
               B.Branch_Loc,
               CASE 
                   WHEN S.S_Usr_ID IS NOT NULL THEN 'Student exists'
                   ELSE 'Student does not exist'
               END AS Status
        FROM [System_Users].[STUDENTS] S
        LEFT JOIN [Branches].[TRACKS] T ON S.Track_ID = T.Track_ID
        LEFT JOIN [Branches].[BRANCHES] B ON S.Branch_ID = B.Branch_ID
        INNER JOIN StudentList SL ON S.S_Usr_ID = SL.S_Usr_ID;

        -- Print status messages for each student
        SELECT S_Usr_ID,
               CASE 
                   WHEN Status = 'Student exists' THEN 
                       'Student with ID ' + CAST(S_Usr_ID AS NVARCHAR(10)) + ' unassigned from Track ' + ISNULL(Track_Name, 'Unknown') + ', Branch ' + ISNULL(Branch_Loc, 'Unknown')
                   ELSE 'Student with ID ' + CAST(S_Usr_ID AS NVARCHAR(10)) + ' does not exist'
               END AS StatusMessage
        FROM @StudentStatus;

        -- Update the students' Track_ID and Branch_ID to NULL if they exist
        UPDATE [System_Users].[STUDENTS]
        SET Track_ID = NULL,
            Branch_ID = NULL
        FROM [System_Users].[STUDENTS] S
        INNER JOIN @StudentStatus SS ON S.S_Usr_ID = SS.S_Usr_ID
        WHERE SS.Status = 'Student exists';

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;
        
        -- Rethrow the error and rollback
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
AssignStudentToCourse:
This stored procedure assigns students to a course based on the course name.
It performs the following actions:
1. Retrieves the course ID based on the provided course name.
2. Checks if the provided student IDs exist in the STUDENTS table.
3. Assigns the students to the course if both the course and students exist.
4. Prints relevant messages if either the course or students do not exist.
5. Includes error handling to manage any issues during the transaction.
*/

CREATE PROCEDURE AssignStudentToCourse
    @Std_IDs VARCHAR(MAX),      -- Comma-separated list of student IDs
    @Crs_Name NVARCHAR(100)     -- Name of the course to which students will be assigned
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Clean up input values
        SET @Std_IDs = REPLACE(LTRIM(RTRIM(@Std_IDs)), ' ', '');
        SET @Crs_Name = LTRIM(RTRIM(@Crs_Name));
        
        -- Declare variables to hold the course ID and statuses
        DECLARE @Crs_ID INT;
        DECLARE @StudentStatus TABLE (
            S_Usr_ID INT,
            Status NVARCHAR(50)
        );

        -- Retrieve Course_ID based on the course name
        SELECT @Crs_ID = Crs_ID
        FROM [Courses].[COURSES]
        WHERE REPLACE(LTRIM(RTRIM(Crs_Name)), ' ', '') = REPLACE(@Crs_Name, ' ', '');

        -- Check if the course exists
        IF @Crs_ID IS NULL
        BEGIN
            PRINT 'Course with name ' + @Crs_Name + ' does not exist';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Split the list of student IDs into a table variable
        DECLARE @StudentList TABLE (S_Usr_ID INT);

        INSERT INTO @StudentList (S_Usr_ID)
        SELECT value
        FROM STRING_SPLIT(@Std_IDs, ',');

        -- Check if student IDs exist and insert their status
        INSERT INTO @StudentStatus (S_Usr_ID, Status)
        SELECT SL.S_Usr_ID,
               CASE 
                   WHEN EXISTS (SELECT 1 FROM [System_Users].[STUDENTS] WHERE S_Usr_ID = SL.S_Usr_ID) THEN 'Student exists'
                   ELSE 'Student does not exist'
               END AS Status
        FROM @StudentList SL;

        -- Print status messages for each student
        SELECT S_Usr_ID,
               CASE 
                   WHEN Status = 'Student exists' THEN 
                       'Student with ID ' + CAST(S_Usr_ID AS NVARCHAR(10)) + ' will be assigned to Course ' + @Crs_Name
                   ELSE 'Student with ID ' + CAST(S_Usr_ID AS NVARCHAR(10)) + ' does not exist'
               END AS StatusMessage
        FROM @StudentStatus;

        -- Insert into STUDENT_COURSES table if the student exists
        INSERT INTO [Students].[STUDENT_COURSES] (S_Usr_ID, Crs_ID)
        SELECT S_Usr_ID, @Crs_ID
        FROM @StudentStatus
        WHERE Status = 'Student exists';

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;
        
        -- Rethrow the error and rollback
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

--------------------------------------------------------------------------------------------------------
/*
UnassignStudentFromCourse:
This stored procedure unassigns students from a course based on the course name.
It performs the following actions:
1. Retrieves the course ID based on the provided course name.
2. Checks if the provided student IDs exist in the STUDENTS table.
3. Unassigns the students from the course if both the course and students exist.
4. Prints relevant messages if either the course or students do not exist.
5. Includes error handling to manage any issues during the transaction.
*/
CREATE PROCEDURE UnassignStudentFromCourse
    @Std_IDs VARCHAR(MAX),      -- Comma-separated list of student IDs
    @Crs_Name NVARCHAR(100)     -- Name of the course from which students will be unassigned
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Clean up input values
        SET @Std_IDs = REPLACE(LTRIM(RTRIM(@Std_IDs)), ' ', '');
        SET @Crs_Name = LTRIM(RTRIM(@Crs_Name));

        -- Declare variables to hold the course ID and statuses
        DECLARE @Crs_ID INT;
        DECLARE @StudentStatus TABLE (
            S_Usr_ID INT,
            Status NVARCHAR(50)
        );

        -- Retrieve Course_ID based on the course name
        SELECT @Crs_ID = Crs_ID
        FROM [Courses].[COURSES]
        WHERE REPLACE(LTRIM(RTRIM(Crs_Name)), ' ', '') = REPLACE(@Crs_Name, ' ', '');

        -- Check if the course exists
        IF @Crs_ID IS NULL
        BEGIN
            PRINT 'Course with name ' + @Crs_Name + ' does not exist';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Split the list of student IDs into a table variable
        DECLARE @StudentList TABLE (S_Usr_ID INT);

        INSERT INTO @StudentList (S_Usr_ID)
        SELECT value
        FROM STRING_SPLIT(@Std_IDs, ',');

        -- Check if student IDs exist and insert their status
        INSERT INTO @StudentStatus (S_Usr_ID, Status)
        SELECT SL.S_Usr_ID,
               CASE 
                   WHEN EXISTS (SELECT 1 FROM [System_Users].[STUDENTS] WHERE S_Usr_ID = SL.S_Usr_ID) THEN 'Student exists'
                   ELSE 'Student does not exist'
               END AS Status
        FROM @StudentList SL;

        -- Delete from STUDENT_COURSES table if the student exists
        DELETE FROM [Students].[STUDENT_COURSES]
        WHERE S_Usr_ID IN (SELECT S_Usr_ID FROM @StudentStatus WHERE Status = 'Student exists')
          AND Crs_ID = @Crs_ID;

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;
        
        -- Rethrow the error and rollback
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

--------------------------------------------------------------------------------------------------------
/*
GetStudentCoursesInfo:
This stored procedure retrieves the course information for a list of students.
It performs the following actions:
1. Checks if the students with the provided IDs exist in the STUDENTS table.
2. Retrieves and displays the course information for students who exist, including student names and course details.
3. Prints a relevant message if any student IDs do not exist.
4. Includes error handling and transaction management to ensure data consistency and manage exceptions.
*/
CREATE PROCEDURE GetStudentCoursesInfo
    @Std_IDs VARCHAR(MAX)  -- Comma-separated list of student IDs
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Clean up input value
        SET @Std_IDs = REPLACE(LTRIM(RTRIM(@Std_IDs)), ' ', '');

        -- Declare a table variable to hold student IDs and their statuses
        DECLARE @StudentStatus TABLE (
            S_Usr_ID INT,
            Status NVARCHAR(50)
        );

        -- Split the list of student IDs into a table variable and check if they exist
        INSERT INTO @StudentStatus (S_Usr_ID, Status)
        SELECT SL.value,
               CASE 
                   WHEN EXISTS (SELECT 1 FROM [System_Users].[STUDENTS] S WHERE S_Usr_ID = SL.value) THEN 'Student exists'
                   ELSE 'Student does not exist'
               END AS Status
        FROM STRING_SPLIT(@Std_IDs, ',') SL;

        -- Print a message if any student IDs do not exist
        SELECT S_Usr_ID,
               CASE 
                   WHEN Status = 'Student does not exist' THEN 
                       'Student with ID ' + CAST(S_Usr_ID AS NVARCHAR(10)) + ' does not exist'
                   ELSE NULL
               END AS StatusMessage
        FROM @StudentStatus
        WHERE Status = 'Student does not exist';

        -- Retrieve student course information if students exist
        SELECT
            S.S_Usr_ID,
            CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS StudentName,
            C.Crs_ID,
            C.Crs_Name
        FROM [System_Users].[USRS] U
        INNER JOIN [System_Users].[STUDENTS] S ON U.Usr_ID = S.S_Usr_ID
        INNER JOIN [Students].[STUDENT_COURSES] SC ON S.S_Usr_ID = SC.S_Usr_ID
        INNER JOIN [Courses].[COURSES] C ON SC.Crs_ID = C.Crs_ID
        INNER JOIN @StudentStatus SS ON S.S_Usr_ID = SS.S_Usr_ID
        WHERE SS.Status = 'Student exists'
        ORDER BY S.S_Usr_ID;

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;
        
        -- Rethrow the error and rollback
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;
---------------------------------------------------------------------------------------------------------
/*
GetCourseStudentsInfo :
This stored procedure retrieves student information for a list of courses based on course names.
It performs the following actions:
1. Retrieves the course IDs based on the provided course names.
2. Checks if the courses with the provided names exist in the COURSES table.
3. Retrieves and displays student information for valid courses, including student names and course details.
4. Prints a relevant message if any course names do not exist.
5. Includes error handling and transaction management to ensure data consistency and manage exceptions.
*/
CREATE PROCEDURE GetCourseStudentsInfo
    @Crs_Names NVARCHAR(MAX)  -- Comma-separated list of course names
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Clean up input value
        SET @Crs_Names = REPLACE(LTRIM(RTRIM(@Crs_Names)), ' ', '');

        -- Declare a table variable to hold course names and their IDs
        DECLARE @CourseStatus TABLE (
            Crs_Name NVARCHAR(100),
            Crs_ID INT,
            Status NVARCHAR(50)
        );

        -- Split the list of course names into a table variable and check if they exist
        INSERT INTO @CourseStatus (Crs_Name, Crs_ID, Status)
        SELECT 
            SL.value AS Crs_Name,
            C.Crs_ID,
            CASE 
                WHEN C.Crs_ID IS NOT NULL THEN 'Course exists'
                ELSE 'Course does not exist'
            END AS Status
        FROM STRING_SPLIT(@Crs_Names, ',') SL
        LEFT JOIN [Courses].[COURSES] C ON C.Crs_Name = SL.value;

        -- Print a message if any course names do not exist
        SELECT Crs_Name,
               CASE 
                   WHEN Status = 'Course does not exist' THEN 
                       'Course with name ' + Crs_Name + ' does not exist'
                   ELSE NULL
               END AS StatusMessage
        FROM @CourseStatus
        WHERE Status = 'Course does not exist';

        -- Retrieve student information for courses that exist
        SELECT
            C.Crs_ID,
            C.Crs_Name,
            S.S_Usr_ID,
            CONCAT(U.Usr_Fname, ' ', ISNULL(U.Usr_Mname, ''), ' ', U.Usr_Lname) AS StudentName
        FROM [System_Users].[USRS] U
        INNER JOIN [System_Users].[STUDENTS] S ON U.Usr_ID = S.S_Usr_ID
        INNER JOIN [Students].[STUDENT_COURSES] SC ON S.S_Usr_ID = SC.S_Usr_ID
        INNER JOIN [Courses].[COURSES] C ON SC.Crs_ID = C.Crs_ID
        INNER JOIN @CourseStatus CS ON C.Crs_ID = CS.Crs_ID
        WHERE CS.Status = 'Course exists'
        ORDER BY C.Crs_ID, S.S_Usr_ID;

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;
        
        -- Rethrow the error and rollback
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;

---------------------------------------------------------------------------------------------------------
/*
InsertStudentAnswer:
This stored procedure inserts a student's answer into the STUDENT_ANSWERS table.
It performs the following actions:
1. Inserts the student's answer along with the student ID, question ID, and exam ID into the table.
2. Includes error handling to manage potential issues during the insert operation.
3. Provides a success message upon successful insertion.
4. Utilizes transaction management to ensure data consistency.
*/

CREATE PROCEDURE InsertStudentAnswer
    @S_Usr_ID INT,          -- Student ID
    @Q_ID INT,              -- Question ID
    @Exam_ID INT,           -- Exam ID
    @Std_Answer VARCHAR(200) -- Student's answer
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Clean up the student answer input
        SET @Std_Answer = LTRIM(RTRIM(@Std_Answer));

        -- Check if the student exists
        IF NOT EXISTS (SELECT 1 FROM [System_Users].[STUDENTS] WHERE S_Usr_ID = @S_Usr_ID)
        BEGIN 
            -- Rollback the transaction if student does not exist
            PRINT 'Student does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check if the exam exists
        IF NOT EXISTS (SELECT 1 FROM [Courses].[EXAMS] WHERE Exam_ID = @Exam_ID)
        BEGIN
            PRINT 'Exam with ID ' + CAST(@Exam_ID AS NVARCHAR) + ' does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check if the question exists within the specified exam
        IF NOT EXISTS (SELECT 1 FROM [Courses].[EXAM_GEN] WHERE Q_ID = @Q_ID AND Exam_ID = @Exam_ID)
        BEGIN
            PRINT 'Question with ID ' + CAST(@Q_ID AS NVARCHAR) + ' does not exist in Exam ID ' + CAST(@Exam_ID AS NVARCHAR) + '.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insert the student's answer into STUDENT_ANSWERS table
        INSERT INTO [Students].[STUDENT_ANSWERS] (S_Usr_ID, Q_ID, Exam_ID, Std_Answer)
        VALUES (@S_Usr_ID, @Q_ID, @Exam_ID, @Std_Answer);

        -- Commit the transaction if the insert is successful
        COMMIT TRANSACTION;
        PRINT 'Student answer inserted successfully.';
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;
        
        -- Rethrow the error and rollback
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;
GO

--------------------------------------------------------------------------------------------------------
/*
GetStudentExamResults:
- This stored procedure retrieves exam results for a student, including the number of correct and wrong answers, the total number of questions, and the student's score.
- It first checks if both the student and the exam exist in the `STUDENT_ANSWERS` table.
- If the student does not exist, it prints a message and rolls back the transaction.
- If the exam does not exist, it prints a message and rolls back the transaction.
- It calculates the number of correct and wrong answers, the total number of questions, and computes the student's score as a percentage.
- It updates the student's score in the `STUDENT_COURSES` table based on the `Crs_ID` associated with the exam.
- Transactions are used to ensure data integrity, and error handling is implemented using TRY...CATCH.
*/
CREATE PROCEDURE GetStudentExamResults
    @S_Usr_ID INT,          -- Student ID
    @Exam_ID INT            -- Exam ID
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Check if the student exists
        IF NOT EXISTS (SELECT 1 FROM [System_Users].[STUDENTS] WHERE S_Usr_ID = @S_Usr_ID)
        BEGIN
            PRINT 'Student does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END 

        -- Check if the exam exists
        IF NOT EXISTS (SELECT 1 FROM [Exams].[EXAMS] WHERE Exam_ID = @Exam_ID)
        BEGIN
            PRINT 'Exam does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Declare variables
        DECLARE @CorrectAnswers INT;
        DECLARE @WrongAnswers INT;
        DECLARE @TotalQuestions INT;
        DECLARE @Score INT;
        DECLARE @Crs_ID INT;

        -- Calculate the number of correct answers
        SET @CorrectAnswers = 
        (
            SELECT COUNT(*)
            FROM [Students].[STUDENT_ANSWERS]
            WHERE Status = 1 AND S_Usr_ID = @S_Usr_ID AND Exam_ID = @Exam_ID
        );

        -- Calculate the number of wrong answers
        SET @WrongAnswers = 
        (
            SELECT COUNT(*)
            FROM [Students].[STUDENT_ANSWERS]
            WHERE Status = 0 AND S_Usr_ID = @S_Usr_ID AND Exam_ID = @Exam_ID
        );

        -- Calculate the total number of questions
        SET @TotalQuestions = 
        (
            SELECT COUNT(DISTINCT Q_ID)
            FROM [Students].[STUDENT_ANSWERS]
            WHERE S_Usr_ID = @S_Usr_ID AND Exam_ID = @Exam_ID
        );

        -- Calculate the score, avoid division by zero
        IF @TotalQuestions > 0
            SET @Score = (@CorrectAnswers * 100) / @TotalQuestions;
        ELSE
            SET @Score = 0;

        -- Return the results
        SELECT @CorrectAnswers AS Correct_Answers,
               @WrongAnswers AS Wrong_Answers,            
               @TotalQuestions AS Exam_Questions,
               CAST(@Score AS VARCHAR(3)) + ' %' AS Student_Score;

        -- Get the Crs_ID of the Exam
        SELECT @Crs_ID = Crs_ID 
        FROM [Courses].[COURSES]  -- Assuming the correct table for courses
        WHERE Crs_ID = 
        (
            SELECT Crs_ID 
            FROM [Courses].[EXAMS]
            WHERE Exam_ID = @Exam_ID
        );

        -- Update the student's score in the STUDENT_COURSES table
        UPDATE [Students].[STUDENT_COURSES]
        SET Score = CAST(@Score AS VARCHAR(5)) + ' %'
        WHERE S_Usr_ID = @S_Usr_ID AND Crs_ID = @Crs_ID;

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction if an error occurs
        ROLLBACK TRANSACTION;

        -- Optionally, raise an error message
        PRINT 'An error occurred while retrieving the student exam results.';
        THROW;
    END CATCH;
END;

GO

--------------------------------------------------------------------------------------------------------
/*
AddNewCertificate:
- This stored procedure inserts a new certificate into the `CERTIFICATES` table.
- It first trims leading and trailing spaces from the certificate name.
- It checks if the certificate already exists (case-insensitive) by removing spaces and comparing it to the new name.
  - If the certificate exists, it prints a message indicating that the certificate already exists.
  - If the certificate does not exist, it inserts the new certificate and prints a success message.
- Transactions are used to ensure data integrity, and error handling is implemented using TRY...CATCH.
*/
CREATE PROCEDURE AddNewCertificate
    @Cer_Name VARCHAR(100)  -- Certificate name to insert
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Trim leading and trailing spaces from the certificate name
        SET @Cer_Name = LTRIM(RTRIM(@Cer_Name));
        
        -- Check if the certificate already exists (case-insensitive)
        IF EXISTS (SELECT 1 
                   FROM [Students].[CERTIFICATES] 
                   WHERE REPLACE(LTRIM(RTRIM(Cer_Name)), ' ', '')  = REPLACE(@Cer_Name, ' ', '') )
            -- If certificate exists, print message
        BEGIN
			PRINT 'Certificate already exists.';
			ROLLBACK TRANSACTION ; 
			RETURN ;
        END
        ELSE
        BEGIN
            -- Insert new certificate if it doesn't exist
            INSERT INTO [Students].[CERTIFICATES] (Cer_Name)
            VALUES (@Cer_Name);

            -- Print success message
            PRINT 'Certificate inserted successfully.';
        END;

        -- Commit the transaction if everything succeeds
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction in case of an error
        ROLLBACK TRANSACTION;

        -- Print error message and re-raise the error
        PRINT 'An error occurred while inserting the certificate.';
        THROW;
    END CATCH;
END;
GO

---------------------------------------------------------------------------------------------------------
/*
EditCertificate :
This stored procedure updates a certificate's name based on the provided old and new names:
1. Trims both the old and new certificate names for leading and trailing spaces.
2. Searches if a certificate with the old name (case-insensitive) exists in the CERTIFICATES table.
3. If the old certificate exists, updates it with the new name using COALESCE (to handle cases where the new name is NULL).
4. If the old certificate does not exist, it prints a relevant message.
5. Includes error handling and transaction management to ensure data consistency.
*/

CREATE PROCEDURE EditCertificate
    @Old_Cer_Name VARCHAR(100),  -- The existing certificate name
    @New_Cer_Name VARCHAR(100)   -- The new certificate name to update (optional)
AS
BEGIN
    -- Start transaction
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Trim leading and trailing spaces from both certificate names
        SET @Old_Cer_Name = LTRIM(RTRIM(@Old_Cer_Name));
        SET @New_Cer_Name = LTRIM(RTRIM(@New_Cer_Name));

        -- Declare a variable to store the certificate ID
        DECLARE @Cer_ID INT;

        -- Check if the old certificate exists and retrieve its ID
        SELECT @Cer_ID = Cer_ID
        FROM [Students].[CERTIFICATES]
        WHERE REPLACE(LTRIM(RTRIM(Cer_Name)), ' ', '') = REPLACE(@Old_Cer_Name, ' ', '');

        -- If the certificate exists, update it with the new name (using COALESCE to handle NULLs)
        IF @Cer_ID IS NOT NULL
        BEGIN
            UPDATE [Students].[CERTIFICATES]
            SET Cer_Name = COALESCE(@New_Cer_Name, Cer_Name)  -- If @New_Cer_Name is NULL, keep the old name
            WHERE Cer_ID = @Cer_ID;

            -- Print success message
            PRINT 'Certificate updated successfully.';
        END
        ELSE
        BEGIN
            -- If the old certificate does not exist, insert the new certificate
            PRINT 'Certificate with the name :' + @Old_Cer_Name + ' not exists'
			INSERT INTO [Students].[CERTIFICATES] (Cer_Name)
            VALUES (@New_Cer_Name);

            -- Print success message
            PRINT 'Certificate with name "' + @New_Cer_Name + '" inserted successfully.';
        END;

        -- Commit the transaction if everything succeeds
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction in case of an error
        ROLLBACK TRANSACTION;

        -- Print error message and re-raise the error
        PRINT 'An error occurred while updating or inserting the certificate.';
        THROW;
    END CATCH;
END;
GO

---------------------------------------------------------------------------------------------------------
/*
50-RemoveCertificate:
This stored procedure deletes a certificate based on its name:
1. Takes the certificate name as input and trims leading/trailing spaces.
2. Searches for the certificate by name (case-insensitive).
3. If the certificate exists, retrieves its ID and deletes it.
4. If the certificate does not exist, prints a message indicating so.
5. Uses TRY...CATCH to handle errors and transaction management to ensure data consistency.
*/
CREATE PROCEDURE RemoveCertificate
    @Cer_Name VARCHAR(100)  -- The certificate name to delete
AS
BEGIN
    -- Start transaction
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Trim leading and trailing spaces from certificate name
        SET @Cer_Name = LTRIM(RTRIM(@Cer_Name));

        -- Declare a variable to store the certificate ID
        DECLARE @Cer_ID INT;

        -- Check if the certificate exists and retrieve its ID
        SELECT @Cer_ID = Cer_ID
        FROM [Students].[CERTIFICATES]
        WHERE REPLACE(LTRIM(RTRIM(Cer_Name)), ' ', '') = REPLACE(@Cer_Name, ' ', '');

        -- If the certificate exists, delete it
        IF @Cer_ID IS NOT NULL
        BEGIN
            DELETE FROM [Students].[CERTIFICATES]
            WHERE Cer_ID = @Cer_ID;

            -- Print success message
            PRINT 'Certificate with the name "'+ @Cer_Name + '" deleted successfully ';
        END
        ELSE
        BEGIN
            -- Print message if the certificate does not exist
            PRINT 'Certificate with the name "' + @Cer_Name + '" does not exist.';
        END;

        -- Commit the transaction if everything succeeds
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction in case of an error
        ROLLBACK TRANSACTION;

        -- Raise the error for the caller to handle
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

---------------------------------------------------------------------------------------------------------
/*
GetCertificateInfo : 
This stored procedure retrieves certificate information based on certificate names:
1. Takes certificate names as input (comma-separated) and trims any leading/trailing spaces.
2. Searches for certificates by name (case-insensitive).
3. If the certificates exist, retrieves their IDs and displays their details.
4. If any certificate does not exist, prints a relevant message.
5. Implements error handling with TRY...CATCH and uses transaction management for data consistency.
*/
CREATE PROCEDURE GetCertificateInfo
    @Cer_Names VARCHAR(MAX) = NULL  -- Comma-separated list of certificate names
AS
BEGIN
    BEGIN TRY
        -- Trim leading and trailing spaces from certificate names
        SET @Cer_Names = LTRIM(RTRIM(@Cer_Names));

        -- Declare table variable to hold results
        DECLARE @Certificates TABLE (
            Cer_ID INT,
            Cer_Name VARCHAR(100)
        );

        -- Check if certificate names are provided
        IF @Cer_Names IS NULL
        BEGIN
            -- Select all certificates if no specific names are provided
            INSERT INTO @Certificates
            SELECT Cer_ID, Cer_Name
            FROM [Students].[CERTIFICATES];
        END
        ELSE
        BEGIN
            -- Search for certificates by name (case-insensitive)
            INSERT INTO @Certificates
            SELECT Cer_ID, Cer_Name
            FROM [Students].[CERTIFICATES]
            WHERE REPLACE(LTRIM(RTRIM(Cer_Name)), ' ', '') IN (
                SELECT REPLACE(value, ' ', '') 
                FROM STRING_SPLIT(@Cer_Names, ',')
            );

            -- Check if any records were found
            IF (SELECT COUNT(*) FROM @Certificates) = 0
            BEGIN
                -- Print message if no certificates are found
                PRINT 'No certificates found with the provided names.';
                RETURN;
            END
        END

        -- Display the retrieved certificates
        SELECT * FROM @Certificates;

    END TRY
    BEGIN CATCH
        -- Print error message and re-raise the error
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

---------------------------------------------------------------------------------------------------------
/*
AssignStudentToCertificate : 
This stored procedure assigns a student to a certificate:
1. Takes `Cer_Name` 
2. Searches for the certificate by name . If found, retrieves its ID.
3. Searches for the student by ID to verify if the student exists.
4. If both certificate and student exist, assigns the student to the certificate.
5. If the certificate or student doesn't exist, prints a relevant message.
6. Implements error handling with TRY...CATCH and uses transaction management for data consistency.
*/
CREATE PROCEDURE AssignStudentToCertificate
    @S_Usr_ID INT,
    @Cer_Name VARCHAR(100),
    @Cer_Date DATE,
    @Cer_Code VARCHAR(10) = NULL -- optional parameter 
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Trim leading and trailing spaces from the certificate name
        SET @Cer_Name = LTRIM(RTRIM(@Cer_Name));

        -- Declare variable to hold the certificate ID
        DECLARE @Cer_ID INT;

        -- Check if the certificate exists
        SELECT @Cer_ID = Cer_ID
        FROM [Students].[CERTIFICATES]
        WHERE REPLACE(LTRIM(RTRIM(Cer_Name)), ' ', '') = REPLACE(@Cer_Name, ' ', '');

        -- If the certificate doesn't exist, print a relevant message and rollback
        IF @Cer_ID IS NULL
        BEGIN
            PRINT 'Certificate "'+@Cer_Name +'" not found.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check if the student exists
        IF NOT EXISTS (SELECT 1 FROM [System_Users].[STUDENTS] WHERE S_Usr_ID = @S_Usr_ID)
        BEGIN
            PRINT 'Student ID "'+ @S_Usr_ID +'" not found.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check if the student is already assigned to the certificate
        IF EXISTS (SELECT 1 FROM [Students].[STUDENT_CERTIFICATES] WHERE S_Usr_ID = @S_Usr_ID AND Cer_ID = @Cer_ID)
        BEGIN
            PRINT 'Student is already assigned to this certificate.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insert the student-certificate assignment
        INSERT INTO [Students].[STUDENT_CERTIFICATES] (S_Usr_ID, Cer_ID, Cer_Date, Cer_Code)
        VALUES (@S_Usr_ID, @Cer_ID, @Cer_Date, @Cer_Code);

        -- Success message
        PRINT 'Student assigned to the certificate successfully.';

        -- Commit the transaction if successful
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction in case of error
        ROLLBACK TRANSACTION;

        -- Print error message and re-raise the error
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

---------------------------------------------------------------------------------------------------------
/*
UnassignStudentFromCertificate:
This stored procedure unassigns a student from a certificate:
1. Takes `Cer_Name` instead of `Cer_ID` to find the certificate.
2. Searches for the certificate by name (case-insensitive). If found, retrieves its ID.
3. Searches for the student by ID to verify if the student exists.
4. If both certificate and student exist and the student is assigned, unassigns the student from the certificate.
5. If the certificate or student doesn't exist, prints a relevant message.
6. Implements error handling with TRY...CATCH and uses transaction management for data consistency.
*/

CREATE PROCEDURE UnassignStudentFromCertificate
    @S_Usr_ID INT,
    @Cer_Name VARCHAR(100)
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Trim leading and trailing spaces from the certificate name
        SET @Cer_Name = LTRIM(RTRIM(@Cer_Name));

        -- Declare variable to hold the certificate ID
        DECLARE @Cer_ID INT;

        -- Check if the certificate exists
        SELECT @Cer_ID = Cer_ID
        FROM [Students].[CERTIFICATES]
        WHERE REPLACE(LTRIM(RTRIM(Cer_Name)), ' ', '') = REPLACE(@Cer_Name, ' ', '');

        -- If the certificate doesn't exist, print a relevant message and rollback
        IF @Cer_ID IS NULL
        BEGIN
            RAISERROR('Certificate "%s" not found.', 16, 1, @Cer_Name);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check if the student exists
        IF NOT EXISTS (SELECT 1 FROM [System_Users].[STUDENTS] WHERE S_Usr_ID = @S_Usr_ID)
        BEGIN
            RAISERROR('Student ID %d not found.', 16, 1, @S_Usr_ID);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check if the student is assigned to the certificate
        IF EXISTS (SELECT 1 FROM [Students].[STUDENT_CERTIFICATES] WHERE S_Usr_ID = @S_Usr_ID AND Cer_ID = @Cer_ID)
        BEGIN
            -- Unassign the student from the certificate
            DELETE FROM [Students].[STUDENT_CERTIFICATES] WHERE S_Usr_ID = @S_Usr_ID AND Cer_ID = @Cer_ID;
            PRINT 'Student unassigned from the certificate successfully.';
        END
        ELSE
        BEGIN
            -- If the assignment doesn't exist, print a message
            RAISERROR('The student is not assigned to the certificate "%s".', 16, 1, @Cer_Name);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Commit the transaction if successful
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction in case of error
        ROLLBACK TRANSACTION;

        -- Print error message and re-raise the error
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

---------------------------------------------------------------------------------------------------------
/*
GetCertificateStudentsInfo: 
This stored procedure retrieves student information assigned to specific certificates:
1. Takes `Cer_Names` (comma-separated) instead of `Cer_IDs`.
2. Searches for each certificate by name (case-insensitive). If found, retrieves its ID.
3. Displays students assigned to the certificate(s) along with the certificate details.
4. If a certificate is not found, prints a relevant message.
5. Implements error handling with TRY...CATCH and uses transaction management for data consistency.
*/
CREATE PROCEDURE GetCertificateStudentsInfo
    @Cer_Names VARCHAR(MAX) = NULL  -- Comma-separated certificate names or NULL for all
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Check if Cer_Names is NULL, select all certificates and their assigned students
        IF @Cer_Names IS NULL
        BEGIN
            -- Select all certificates and their assigned students
            SELECT  C.Cer_ID, C.Cer_Name, 
                    S.S_Usr_ID, CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS StudentName, 
                    SC.Cer_Date, SC.Cer_Code  
            FROM [Students].[CERTIFICATES] C
            INNER JOIN [Students].[STUDENT_CERTIFICATES] SC
                ON C.Cer_ID = SC.Cer_ID
            INNER JOIN [System_Users].[STUDENTS] S
                ON S.S_Usr_ID = SC.S_Usr_ID
            INNER JOIN [System_Users].[USRS] U 
                ON U.Usr_ID = S.S_Usr_ID
            ORDER BY C.Cer_ID;
        END
        ELSE
        BEGIN
            -- Process each certificate name
            WITH CertificateIDs AS (
                SELECT 
                    REPLACE(LTRIM(RTRIM(Cer_Name)), ' ', '') AS CleanCerName, 
                    Cer_ID
                FROM [Students].[CERTIFICATES]
                WHERE REPLACE(LTRIM(RTRIM(Cer_Name)), ' ', '') IN (
                    SELECT REPLACE(LTRIM(RTRIM(value)), ' ', '') 
                    FROM STRING_SPLIT(@Cer_Names, ',')
                )
            )
            SELECT  C.Cer_ID, C.Cer_Name, 
                    S.S_Usr_ID, CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS StudentName, 
                    SC.Cer_Date, SC.Cer_Code  
            FROM [Students].[CERTIFICATES] C
            INNER JOIN [Students].[STUDENT_CERTIFICATES] SC
                ON C.Cer_ID = SC.Cer_ID
            INNER JOIN [System_Users].[STUDENTS] S
                ON S.S_Usr_ID = SC.S_Usr_ID
            INNER JOIN [System_Users].[USRS] U 
                ON U.Usr_ID = S.S_Usr_ID
            INNER JOIN CertificateIDs CI
                ON C.Cer_ID = CI.Cer_ID
            ORDER BY C.Cer_ID;
        END

        -- Commit transaction if everything is successful
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback transaction in case of error
        ROLLBACK TRANSACTION;

        -- Print error message and re-raise the error
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO
--------------------------------------------------------------------------------------------------------
/*
GetStudentCertificatesInfo :
This stored procedure retrieves information about certificates assigned to students. 
It can handle both individual and multiple students. It:
1. Takes a comma-separated list of student IDs or NULL to retrieve all students' information.
2. If IDs are provided, it retrieves and displays the certificates assigned to these students.
3. If no IDs are provided, it retrieves and displays all students' certificate assignments.
*/
CREATE PROCEDURE GetStudentCertificatesInfo
    @S_Usr_IDs VARCHAR(MAX) = NULL  -- Comma-separated student IDs or NULL for all
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        IF @S_Usr_IDs IS NULL
        BEGIN
            -- Select all students and their assigned certificates
            SELECT  S.S_Usr_ID, CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS StudentName,
                    C.Cer_ID, C.Cer_Name, 
                    SC.Cer_Date, SC.Cer_Code  
            FROM [Students].[CERTIFICATES] C
            INNER JOIN [Students].[STUDENT_CERTIFICATES] SC
                ON C.Cer_ID = SC.Cer_ID
            INNER JOIN [System_Users].[STUDENTS] S
                ON S.S_Usr_ID = SC.S_Usr_ID
            INNER JOIN [System_Users].[USRS] U 
                ON U.Usr_ID = S.S_Usr_ID
            ORDER BY S.S_Usr_ID;
        END
        ELSE
        BEGIN
            -- Select specific students and their assigned certificates based on provided IDs
            SELECT  S.S_Usr_ID, CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS StudentName,
                    C.Cer_ID, C.Cer_Name, 
                    SC.Cer_Date, SC.Cer_Code  
            FROM [Students].[CERTIFICATES] C
            INNER JOIN [Students].[STUDENT_CERTIFICATES] SC
                ON C.Cer_ID = SC.Cer_ID
            INNER JOIN [System_Users].[STUDENTS] S
                ON S.S_Usr_ID = SC.S_Usr_ID
            INNER JOIN [System_Users].[USRS] U 
                ON U.Usr_ID = S.S_Usr_ID
            WHERE S.S_Usr_ID IN (
                SELECT REPLACE(LTRIM(RTRIM(value)), ' ', '') 
                FROM STRING_SPLIT(@S_Usr_IDs, ',')
            )
            ORDER BY S.S_Usr_ID;
        END

        -- Commit transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction if an error occurs
        ROLLBACK TRANSACTION;

        -- Raise error message
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

--------------------------------------------------------------------------------------------------------
/*
AddNewFreelancingJob : 
This stored procedure handles the insertion of a new freelancing job title into the FREELANCING_JOBS table.
1. It takes a job title as input.
2. It checks if the job title already exists in the table.
3. If the job title exists, it prints a message indicating that it already exists.
4. If the job title does not exist, it inserts the new job title into the table and prints a success message.
*/

CREATE PROCEDURE AddNewFreelancingJob
    @FJ_JobTitle VARCHAR(100)  -- Job title to insert
AS
BEGIN
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Trim leading and trailing spaces
        SET @FJ_JobTitle = LTRIM(RTRIM(@FJ_JobTitle));
        
        -- Check if the job title already exists (case-insensitive)
        IF EXISTS (SELECT 1 
                   FROM [Students].[FREELANCING_JOBS] 
                   WHERE REPLACE(LTRIM(RTRIM(FJ_JobTitle)), ' ', '') = REPLACE(@FJ_JobTitle, ' ', ''))
        BEGIN
            -- If job title exists, print message and rollback
            PRINT 'Job title already exists.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Insert new job title if it does not exist
        INSERT INTO [Students].[FREELANCING_JOBS] (FJ_JobTitle)
        VALUES (@FJ_JobTitle);

        -- Success message
        PRINT 'Job added successfully.';

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction if an error occurs
        ROLLBACK TRANSACTION;

        -- Raise error message
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
            
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

-------------------------------------------------------------------------------------------------------
/*
EditFreelancingJob:
This stored procedure updates a freelancing job title in the FREELANCING_JOBS table.
1. It takes the current job title and the new job title as input.
2. It checks if the current job title exists in the table.
3. If the current job title exists:
   - It retrieves the ID of the current job title.
   - If the new job title does not already exist in the table, it updates the job title.
   - If the new job title already exists (excluding the current job), it prints a message indicating the job title already exists.
4. If the current job title does not exist, it prints a message indicating the job ID does not exist.
*/


CREATE PROCEDURE EditFreelancingJob
    @CurrentJobTitle VARCHAR(100),  -- Current job title to be updated
    @NewJobTitle VARCHAR(100)       -- New job title
AS
BEGIN
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Trim leading and trailing spaces
        SET @CurrentJobTitle = LTRIM(RTRIM(@CurrentJobTitle));
        SET @NewJobTitle = LTRIM(RTRIM(@NewJobTitle));

        -- Check if the current job title exists
        DECLARE @FJ_ID INT;

        SELECT @FJ_ID = FJ_ID
        FROM [Students].[FREELANCING_JOBS]
        WHERE REPLACE(LTRIM(RTRIM(FJ_JobTitle)), ' ', '') = REPLACE(@CurrentJobTitle, ' ', '');

        IF @FJ_ID IS NULL
        BEGIN
            PRINT 'Job title does not exist. Inserting ...';
            INSERT INTO [Students].[FREELANCING_JOBS] (FJ_JobTitle)
			VALUES(@NewJobTitle);
            RETURN;
        END

        -- Check if the new job title already exists (excluding the current job ID)
        IF EXISTS (SELECT 1 
                   FROM [Students].[FREELANCING_JOBS] 
                   WHERE REPLACE(LTRIM(RTRIM(FJ_JobTitle)), ' ', '') = REPLACE(@NewJobTitle, ' ', '') 
                     AND FJ_ID <> @FJ_ID)
        BEGIN
            PRINT 'Another job with the same title exists';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Update the job title if no conflicts are found
        UPDATE [Students].[FREELANCING_JOBS]
        SET FJ_JobTitle = @NewJobTitle
        WHERE FJ_ID = @FJ_ID;

        -- Success message
        PRINT 'Job updated successfully.';

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction if an error occurs
        ROLLBACK TRANSACTION;

        -- Raise error message with details
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
            
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

---------------------------------------------------------------------------------------------------------
/*
RemoveFreelancingJob: 
This stored procedure deletes a freelancing job based on the job title.
1. It takes the job title as input.
2. It searches for the job title in the FREELANCING_JOBS table.
3. If the job title exists:
   - It retrieves the job ID.
   - It then deletes the job using the retrieved ID.
   - It prints a message indicating successful deletion.
4. If the job title does not exist, it prints a message indicating the job title does not exist.
*/

CREATE PROCEDURE RemoveFreelancingJob
    @FJ_JobTitle VARCHAR(100)
AS
BEGIN
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Trim leading and trailing spaces
        SET @FJ_JobTitle = LTRIM(RTRIM(@FJ_JobTitle));

        -- Check if the job title exists and retrieve the ID
        DECLARE @FJ_ID INT;

        SELECT @FJ_ID = FJ_ID
        FROM [Students].[FREELANCING_JOBS]
        WHERE REPLACE(LTRIM(RTRIM(FJ_JobTitle)), ' ' , '') = REPLACE(@FJ_JobTitle , ' ' , '');

        IF @FJ_ID IS NULL
        BEGIN
            PRINT 'Job title does not exist.';
        END
        ELSE
        BEGIN
            -- Delete the job using the retrieved ID
            DELETE FROM [Students].[FREELANCING_JOBS]
            WHERE FJ_ID = @FJ_ID;
            
            PRINT 'Job deleted successfully.';
        END

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction if an error occurs
        ROLLBACK TRANSACTION;

        -- Raise error message with details
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
            
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;

---------------------------------------------------------------------------------------------------------
/*
The `GetFreelancingJob procedure
- retrieves freelancing job details based on a list of job titles provided as a comma-separated string. The procedure works as follows:
1. Input Cleanup: The input job titles are trimmed of leading/trailing spaces and internal spaces are removed to standardize the data.
2. Job Title Matching: It splits the cleaned job titles using the `string_split` function, which breaks the input string into individual job titles. Each title is then compared to the job titles stored in the `FREELANCING_JOBS` table (with spaces removed for accurate matching).
3. Retrieving Matching Jobs: If any job titles match those in the table, the corresponding job IDs are stored in a table variable (`@JobID`). The procedure then selects the full job details for each of these IDs.
4. Transaction Management: The entire operation is wrapped in a transaction. If any error occurs during execution, the procedure rolls back the transaction and raises an error to ensure data integrity.
This procedure allows for efficiently querying freelancing jobs based on multiple job titles provided in a single input string.
*/
CREATE PROCEDURE GetFreelancingJob
    @JobTitles NVARCHAR(MAX)  -- Comma-separated job titles
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Remove spaces from input
        SET @JobTitles = REPLACE(LTRIM(RTRIM(@JobTitles)), ' ', '');

        -- Declare a table variable to store matching job IDs
        DECLARE @JobID TABLE(FJ_ID INT);

        -- Insert matching job IDs into the table variable
        INSERT INTO @JobID (FJ_ID)
        SELECT FJ_ID
        FROM [Students].[FREELANCING_JOBS]
        WHERE REPLACE(LTRIM(RTRIM(FJ_JobTitle)), ' ', '') IN
            (SELECT REPLACE(value, ' ', '') FROM string_split(@JobTitles, ','));

        -- Select the freelancing jobs using the IDs in @JobID
        SELECT F.*
        FROM [Students].[FREELANCING_JOBS] F
        WHERE F.FJ_ID IN (SELECT FJ_ID FROM @JobID);

        -- Commit the transaction
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback in case of error
        ROLLBACK TRANSACTION;

        -- Raise error message with details
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
            
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;

---------------------------------------------------------------------------------------------------------
/*
AssignStudentToJob :
This stored procedure assigns a student to a freelancing job.
1. It takes the student ID and job details as input.
2. It first checks if the student ID exists in the `STUDENTS` table.
3. It then checks if the job title exists in the `FREELANCING_JOBS` table.
4. If the job title does not exist:
   - It inserts the new job title into `FREELANCING_JOBS`.
   - It retrieves the new job ID.
5. It assigns the student to the job by inserting the details into the `STUDENT_JOBS` table.
6. If the student is assigned successfully, a success message is printed. 
7. Includes `TRY...CATCH` and transactions for error handling and atomicity.
*/

CREATE PROCEDURE AssignStudentToJob
    @S_Usr_ID INT,
    @FJ_JobTitle VARCHAR(100),
    @FJ_Description VARCHAR(300),
    @FJ_Duration INT,
    @FJ_Date DATE,
    @FJ_Platform VARCHAR(50),
    @FJ_Cost MONEY,
    @FJ_PaymentMethod VARCHAR(50)
AS
BEGIN
    -- Start transaction to ensure data consistency
    BEGIN TRANSACTION;
    
    BEGIN TRY
        DECLARE @FJ_ID INT;
		
        -- Trim job title to handle unnecessary spaces
        SET @FJ_JobTitle = LTRIM(RTRIM(@FJ_JobTitle));

        -- Verify if the student exists
        IF NOT EXISTS (SELECT 1 FROM [System_Users].[STUDENTS] WHERE S_Usr_ID = @S_Usr_ID)
        BEGIN
            RAISERROR('Student ID does not exist.', 16, 1);
            RETURN;
        END

        -- Check if the job title already exists in the FREELANCING_JOBS table
        SELECT @FJ_ID = FJ_ID
        FROM [Students].[FREELANCING_JOBS]
        WHERE REPLACE(LTRIM(RTRIM(FJ_JobTitle)), ' ', '') = REPLACE(@FJ_JobTitle, ' ', '');

        -- If the job title doesn't exist, insert it and retrieve the new FJ_ID
        IF @FJ_ID IS NULL
        BEGIN
            INSERT INTO [Students].[FREELANCING_JOBS] (FJ_JobTitle)
            VALUES (@FJ_JobTitle);

            -- Retrieve the ID of the newly inserted job
            SET @FJ_ID = SCOPE_IDENTITY();
        END

        -- Assign the student to the job by inserting data into the STUDENT_JOBS table
        INSERT INTO [Students].[STUDENT_JOBS] 
        (S_Usr_ID, FJ_ID, FJ_Description, FJ_Duration, FJ_Date, FJ_Platform, FJ_Cost, FJ_PaymentMethod)
        VALUES 
        (@S_Usr_ID, @FJ_ID, @FJ_Description, @FJ_Duration, @FJ_Date, @FJ_Platform, @FJ_Cost, @FJ_PaymentMethod);

        -- Commit the transaction on successful operation
        COMMIT TRANSACTION;

        PRINT 'Student assigned to the job successfully.';
    END TRY
    BEGIN CATCH
        -- Rollback transaction if any error occurs
        ROLLBACK TRANSACTION;

         -- Raise error message with details
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
            
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;

---------------------------------------------------------------------------------------------------------
/*
60-
This stored procedure unassigns a student from a freelancing job.
1. It takes the student ID and job title as input.
2. It first checks if the student ID exists in the `STUDENTS` table.
3. It then checks if the job title exists in the `FREELANCING_JOBS` table.
4. If the job title exists:
   - It retrieves the job ID.
   - It deletes the student-job relation from the `STUDENT_JOBS` table.
   - It checks if the deletion was successful and prints a message accordingly.
5. If the job title does not exist, it prints a relevant message.
6. Includes `TRY...CATCH` and transactions for error handling and atomicity.
*/

CREATE PROCEDURE UnassignStudentFromJob
    @S_Usr_ID INT,
    @FJ_JobTitle VARCHAR(100)
AS
BEGIN
    BEGIN TRANSACTION;
    
    BEGIN TRY
        DECLARE @FJ_ID INT;

        -- Trim job title to handle any unnecessary spaces
        SET @FJ_JobTitle = LTRIM(RTRIM(@FJ_JobTitle));

        -- Check if the student ID exists in the STUDENTS table
        IF NOT EXISTS (SELECT 1 FROM [System_Users].[STUDENTS] WHERE S_Usr_ID = @S_Usr_ID)
        BEGIN
            RAISERROR('Student ID does not exist.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check if the job title exists in the FREELANCING_JOBS table
        SELECT @FJ_ID = FJ_ID
        FROM [Students].[FREELANCING_JOBS]
        WHERE REPLACE(LTRIM(RTRIM(FJ_JobTitle)), ' ', '') = REPLACE(@FJ_JobTitle, ' ', '');

        -- If the job title exists, delete the student-job relation
        IF @FJ_ID IS NOT NULL
        BEGIN
            DELETE FROM [Students].[STUDENT_JOBS]
            WHERE S_Usr_ID = @S_Usr_ID AND FJ_ID = @FJ_ID;

            -- Check if any rows were deleted
            IF @@ROWCOUNT > 0
            BEGIN
                PRINT 'Student unassigned from the job successfully.';
            END
            ELSE
            BEGIN
                PRINT 'No matching record found for the student and job.';
            END
        END
        ELSE
        BEGIN
            RAISERROR('Job title does not exist.', 16, 1);
        END

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction if any error occurs
        ROLLBACK TRANSACTION;

        -- Raise error message with details
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
            
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;

---------------------------------------------------------------------------------------------------------
/*
GetStudentJobsInfo :
This stored procedure retrieves job information for students.
1. It accepts an optional comma-separated list of student IDs. If no IDs are provided, it retrieves information for all students.
2. It uses a table variable to store student IDs.
3. If specific IDs are provided:
   - The IDs are split and inserted into the table variable.
4. The procedure then selects and displays job information for the specified or all student IDs, including job details from the `FREELANCING_JOBS` table.
5. Includes `TRY...CATCH` and transactions for error handling and ensuring atomicity.
*/
CREATE PROCEDURE GetStudentJobsInfo
    @S_Usr_IDs NVARCHAR(MAX) = NULL  -- Optional: Accept a comma-separated list of Student IDs or NULL for all
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Trim spaces and handle empty input
        SET @S_Usr_IDs = LTRIM(RTRIM(ISNULL(@S_Usr_IDs, '')));

        -- Declare a table variable to store the list of student IDs
        DECLARE @StudentIDs TABLE (S_Usr_ID INT);

        -- If no specific IDs are passed, insert all student IDs from the STUDENTS table
        IF @S_Usr_IDs = ''
        BEGIN
            INSERT INTO @StudentIDs (S_Usr_ID)
            SELECT S_Usr_ID FROM [System_Users].[STUDENTS];
        END
        ELSE
        BEGIN
            -- If specific IDs are passed, split them and insert into the table variable
            INSERT INTO @StudentIDs (S_Usr_ID)
            SELECT CAST(value AS INT)
            FROM STRING_SPLIT(@S_Usr_IDs, ',');
        END

        -- Select the jobs information for the specified or all student IDs
        SELECT  
            S.S_Usr_ID,
            CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS StudentName,
            F.FJ_JobTitle,
            SJ.FJ_Description,
            SJ.FJ_Date,
            SJ.FJ_Duration,
            SJ.FJ_Platform,
            SJ.FJ_Cost,
            SJ.FJ_PaymentMethod
        FROM [System_Users].[USRS] U
        INNER JOIN [System_Users].[STUDENTS] S
            ON U.Usr_ID = S.S_Usr_ID
        INNER JOIN [Students].[STUDENT_JOBS] SJ
            ON S.S_Usr_ID = SJ.S_Usr_ID
        INNER JOIN [Students].[FREELANCING_JOBS] F
            ON F.FJ_ID = SJ.FJ_ID
        WHERE S.S_Usr_ID IN (SELECT S_Usr_ID FROM @StudentIDs)
        ORDER BY S.S_Usr_ID;

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction if an error occurs
        ROLLBACK TRANSACTION;

        -- Optionally, raise an error message
        THROW;
    END CATCH;
END;

--------------------------------------------------------------------------------------------------------
/*
62-
This stored procedure retrieves student job information based on job titles.
1. It accepts an optional comma-separated list of job titles. If no titles are provided, it retrieves information for all jobs.
2. It uses a table variable to store job IDs.
3. If specific job titles are provided:
   - The IDs of these job titles are retrieved from the `FREELANCING_JOBS` table and inserted into the table variable.
4. The procedure then selects and displays student job information for the specified or all job IDs, including job details from the `FREELANCING_JOBS` table.
5. Includes `TRY...CATCH` and transactions for error handling and ensuring atomicity.
*/

CREATE PROCEDURE GetJobStudentsInfo
    @FJ_JobTitle NVARCHAR(MAX) = NULL  -- Optional: Accept a comma-separated list of job titles or NULL for all
AS
BEGIN
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Trim spaces from the input job titles
        SET @FJ_JobTitle = LTRIM(RTRIM(ISNULL(@FJ_JobTitle, '')));

        -- Declare a table variable to store job IDs
        DECLARE @JobIDs TABLE (FJ_ID INT);

        -- If no specific job titles are provided, select all job IDs from the FREELANCING_JOBS table
        IF @FJ_JobTitle = ''
        BEGIN
            INSERT INTO @JobIDs (FJ_ID)
            SELECT FJ_ID FROM [Students].[FREELANCING_JOBS];
        END
        ELSE
        BEGIN
            -- Split the provided job titles and retrieve their IDs
            INSERT INTO @JobIDs (FJ_ID)
            SELECT FJ_ID
            FROM [Students].[FREELANCING_JOBS]
            WHERE REPLACE(LTRIM(RTRIM(FJ_JobTitle)), ' ', '') IN (
                SELECT REPLACE(LTRIM(RTRIM(value)), ' ', '') 
                FROM STRING_SPLIT(@FJ_JobTitle, ',')
            );
        END

        -- Retrieve the students' job information for the specified or all job titles
        SELECT  
            F.FJ_JobTitle,
            S.S_Usr_ID,
            CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS StudentName,
            SJ.FJ_Description,
            SJ.FJ_Date,
            SJ.FJ_Duration,
            SJ.FJ_Platform,
            SJ.FJ_Cost,
            SJ.FJ_PaymentMethod
        FROM [System_Users].[USRS] U
        INNER JOIN [System_Users].[STUDENTS] S
            ON U.Usr_ID = S.S_Usr_ID
        INNER JOIN [Students].[STUDENT_JOBS] SJ
            ON S.S_Usr_ID = SJ.S_Usr_ID
        INNER JOIN [Students].[FREELANCING_JOBS] F
            ON F.FJ_ID = SJ.FJ_ID
        WHERE F.FJ_ID IN (SELECT FJ_ID FROM @JobIDs)
        ORDER BY F.FJ_ID;

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction if an error occurs
        ROLLBACK TRANSACTION;

        -- Optionally, raise an error message
        THROW;
    END CATCH;
END;

-------------------------------------------------------------------------------------------------------------------------




