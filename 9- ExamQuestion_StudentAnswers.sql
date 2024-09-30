EXEC ExamQuestion_StudentAnswer 297 , 200	 -- invalid Exam ID 


EXEC ExamQuestion_StudentAnswer 200 , 24      -- invalid Student ID


EXEC ExamQuestion_StudentAnswer 297 , 24		-- Valid Exam , Valid Student 

EXEC GetStudentExamResults 297 , 24

SELECT * FROM EXAM_GEN
SELECT * FROM STUDENT_ANSWERS
SELECT * FROM QUESTIONS