/* Initialize the transaction */
START TRANSACTION;


/*********************/
/*** ADMIN SECTION ***/
/*********************/

ALTER TABLE admins 
    ADD COLUMN school_id VARCHAR(36) NOT NULL DEFAULT '';

UPDATE admins
    SET access_level = CASE access_level
        WHEN 3 THEN 5
        WHEN 2 THEN 4
        WHEN 1 THEN 2
        WHEN 0 THEN 0
    END
    WHERE access_level IN (1, 2, 3);

ALTER TABLE admins
    ALTER COLUMN school_id DROP DEFAULT;


/***************************/
/*** INTERNSHIPS SECTION ***/
/***************************/
ALTER TABLE internships
    DROP COLUMN school_board_id;

/* ADD ON DELETE CASCADE on student_id to internships table */
SET @fk_name = (
    SELECT CONSTRAINT_NAME
    FROM information_schema.KEY_COLUMN_USAGE
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'internships'
      AND COLUMN_NAME = 'student_id'
      AND REFERENCED_TABLE_NAME = 'students'
    LIMIT 1
);
SET @sql = CONCAT(
    'ALTER TABLE internships ',
    'DROP FOREIGN KEY ', @fk_name, ', ',
    'ADD FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

/* Terminate the transaction */
COMMIT;
