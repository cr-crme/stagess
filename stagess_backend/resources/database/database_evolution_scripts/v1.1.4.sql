/* Create a UUID_v4() function to generate UUIDs for the new junction tables (mariadb < 11.7) */
DELIMITER //

CREATE FUNCTION IF NOT EXISTS UUID_v4() 
RETURNS CHAR(36)
CHARACTER SET utf8mb4
DETERMINISTIC
BEGIN
    -- Generate 16 random bytes
    SET @b = RANDOM_BYTES(16);
    
    RETURN LOWER(CONCAT(
        HEX(SUBSTRING(@b, 1, 4)), '-',
        HEX(SUBSTRING(@b, 5, 2)), '-',
        -- Force the 4 most significant bits of the 3rd group to 0100 (version 4)
        HEX(FROM_BASE64(TO_BASE64(CHAR((ORD(SUBSTRING(@b, 7, 1)) & 0x0f) | 0x40)))),
        HEX(SUBSTRING(@b, 8, 1)), '-',
        -- Force the 2 most significant bits of the 4th group to 10 (variant 1)
        HEX(FROM_BASE64(TO_BASE64(CHAR((ORD(SUBSTRING(@b, 9, 1)) & 0x3f) | 0x80)))),
        HEX(SUBSTRING(@b, 10, 1)), '-',
        HEX(SUBSTRING(@b, 11, 6))
    ));
END//

DELIMITER ;

/* Initialize the transaction */
START TRANSACTION;


/*********************/
/*** ADMIN SECTION ***/
/*********************/

/* Create a junction table to link teachers and theirphone numbers */
CREATE TABLE teacher_professional_phone_numbers(
    teacher_id VARCHAR(36) NOT NULL,
    phone_number_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (phone_number_id) REFERENCES phone_numbers(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);
/* Fill the junction table professional phone numbers with the existing data */
INSERT INTO teacher_professional_phone_numbers (teacher_id, phone_number_id)
    SELECT t.id, pn.id
    FROM teachers t
    JOIN phone_numbers pn
        ON pn.entity_id = t.id;

/* Create a junction table to link teachers and their school phone numbers */
CREATE TABLE teacher_school_phone_numbers(
    teacher_id VARCHAR(36) NOT NULL,
    phone_number_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (phone_number_id) REFERENCES phone_numbers(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);
/* Fill it with empty data */
SET FOREIGN_KEY_CHECKS = 0;
INSERT INTO teacher_school_phone_numbers (teacher_id, phone_number_id)
    SELECT t.id, UUID_v4()
    FROM teachers t
    JOIN phone_numbers pn
        ON pn.entity_id = t.id;
SET FOREIGN_KEY_CHECKS = 1;
/* Adjust the phone numbers table to have a school phone number for each teacher */
INSERT INTO phone_numbers (id, entity_id, phone_number)
    SELECT t.phone_number_id, t.teacher_id, ""
    FROM teacher_school_phone_numbers t;


/* Just realized this column was 36 characters instead of 50 */
ALTER TABLE student_visa_references_items
    MODIFY COLUMN phone_number VARCHAR(50) NOT NULL;


/* Terminate the transaction */
COMMIT;
