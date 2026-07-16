/* Initialize the transaction */
START TRANSACTION;

/*********************/
/*** ADMIN SECTION ***/
/*********************/

UPDATE internship_weekly_schedules
    SET cycle = CASE cycle
        WHEN 0 THEN 1
        WHEN 1 THEN 2
        WHEN 2 THEN 3
    END
    WHERE cycle IN (0, 1, 2);


ALTER TABLE students
    ADD COLUMN teacher_in_charge_id VARCHAR(36)
        AFTER group_name,
    ADD FOREIGN KEY (teacher_in_charge_id) REFERENCES teachers(id);

CREATE TABLE student_supplementary_teachers_in_charge (
    student_id VARCHAR(36) NOT NULL,
    teacher_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id),
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);


/* Terminate the transaction */
COMMIT;
