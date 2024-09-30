SELECT * From COURSES
SELECT * FROM EXAMS

/*Next Exam ID : 27 */
EXEC ExamGeneration 'Data Warehousing for Business Intelligence' ,15,5

SELECT COUNT(*) AS EXAM_NumOfQuestion
FROM EXAM_GEN
WHERE Exam_ID = 27

EXEC ExamPresentation 27
---------------------------------------------------------------------------------------------------------
EXEC ExamGeneration 'AABB' , 15 , 5
---------------------------------------------------------------------------------------------------------