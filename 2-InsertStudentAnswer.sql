SELECT * FROM STUDENTS
SELECT * FROM EXAMS

SELECT * FROM EXAM_GEN 
WHERE Exam_ID = 26

EXEC ExamPresentation 26 


/*Insert Right Answer ( Status = 1 ) */
EXEC InsertStudentAnswer
    @S_Usr_ID =297,
    @Q_ID =184,                    
    @Exam_ID =26,
    @Std_Answer ='True'

SELECT * FROM STUDENT_ANSWERS
WHERE S_Usr_ID = 297 AND Q_ID = 184 AND Exam_ID = 26

SELECT * FROM QUESTIONS
WHERE Q_ID = 184

/*Insert Wrong Answer */
EXEC InsertStudentAnswer
    @S_Usr_ID =297,
    @Q_ID =186,                    
    @Exam_ID =26,
    @Std_Answer ='False'

SELECT * FROM STUDENT_ANSWERS
WHERE S_Usr_ID = 297 AND Q_ID = 185 AND Exam_ID = 26

SELECT * FROM QUESTIONS
WHERE Q_ID = 186

--------------------------------------------------------------------------------------------------------
/*Student Not Exist*/
EXEC InsertStudentAnswer
    @S_Usr_ID =1500,
    @Q_ID =186,                    
    @Exam_ID =26,
    @Std_Answer ='True'
--------------------------------------------------------------------------------------------------------
/*Exam Not Exist*/
EXEC InsertStudentAnswer
    @S_Usr_ID =297,
    @Q_ID =186,                    
    @Exam_ID =200,
    @Std_Answer ='True'

--------------------------------------------------------------------------------------------------------
/*Question Not Exist */
EXEC InsertStudentAnswer
    @S_Usr_ID =297,
    @Q_ID =250,                    
    @Exam_ID =26,
    @Std_Answer ='True'

--------------------------------------------------------------------------------------------------------
