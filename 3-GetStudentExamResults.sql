SELECT * FROM STUDENT_ANSWERS
WHERE S_Usr_ID = 297 AND Exam_ID = 26

SELECT * FROM QUESTIONS
WHERE Q_ID = 186

EXEC GetStudentExamResults 297 , 26

SELECT * FROM STUDENT_COURSES
WHERE S_Usr_ID = 297 

EXEC ExamCorrection 26 


 
