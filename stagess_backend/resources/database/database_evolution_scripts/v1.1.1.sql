DELIMITER //
BEGIN NOT ATOMIC

/***********************/
/* VISA related tables */
/***********************/

/* Check that all the entries conform to the new maximum length for success_conditions before applying the schema changes */ 
IF EXISTS (
    SELECT 1
    FROM student_visa_forms
    WHERE CHAR_LENGTH(success_conditions) > 200
) THEN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Migration aborted: success_conditions exceeds 200 characters';
END IF;

IF EXISTS (
    SELECT 1
    FROM student_visa_forms
    WHERE CHAR_LENGTH(reference) > 0
) THEN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Migration aborted: reference exceeds 0 characters';
END IF;

START TRANSACTION;

/* Create the new tables for the "success conditions" and migrate the data from the old success_conditions column */
CREATE TABLE student_visa_success_conditions_items (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    idx INT NOT NULL,
    visa_form_id VARCHAR(36) NOT NULL,
    text VARCHAR(200) NOT NULL,
    is_selected BOOLEAN NOT NULL,
    FOREIGN KEY (visa_form_id) REFERENCES student_visa_forms(id) ON DELETE CASCADE
);

INSERT INTO student_visa_success_conditions_items (id, idx, visa_form_id, text, is_selected)
    SELECT
        UUID() AS id,
        0 AS idx,
        svf.id AS visa_form_id,
        svf.success_conditions AS text,
        TRUE AS is_selected
    FROM student_visa_forms as svf;

ALTER TABLE student_visa_forms 
    DROP COLUMN success_conditions;


/* Create the new tables for the "references" and migrate the data from the old reference column */
CREATE TABLE student_visa_references_items (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    idx INT NOT NULL,
    visa_form_id VARCHAR(36) NOT NULL,
    is_selected BOOLEAN NOT NULL,
    referee VARCHAR(100) NOT NULL,
    enterprise VARCHAR(100) NOT NULL,
    phone_number VARCHAR(36) NOT NULL,
    email VARCHAR(200) NOT NULL,
    FOREIGN KEY (visa_form_id) REFERENCES student_visa_forms(id) ON DELETE CASCADE
);

/* There is no automatic way to insert values to the tables. That is why it fails on the precedent step */

ALTER TABLE student_visa_forms 
    DROP COLUMN success_conditions, 
    DROP COLUMN reference;


COMMIT;


/* Terminate the transaction */
END //
DELIMITER ;