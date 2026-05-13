DELIMITER //
BEGIN NOT ATOMIC

/***********************/
/* VISA related tables */
/***********************/

/* Sanity check to make sure the migration won't lose data */ 
IF EXISTS (
    SELECT 1
    FROM student_visa_forms
    WHERE CHAR_LENGTH(success_conditions) > 200 OR CHAR_LENGTH(reference) > 200
) THEN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Migration aborted: success_conditions or reference exceeds 200 characters';
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
    supplementary_info VARCHAR(200) NOT NULL,
    FOREIGN KEY (visa_form_id) REFERENCES student_visa_forms(id) ON DELETE CASCADE
);
INSERT INTO student_visa_references_items (id, idx, visa_form_id, is_selected, referee, enterprise, phone_number, email, supplementary_info)
    SELECT
        UUID() AS id,
        0 AS idx,
        svf.id AS visa_form_id,
        TRUE AS is_selected,
        '' AS referee,
        '' AS enterprise,
        '' AS phone_number,
        '' AS email,
        svf.reference AS supplementary_info
    FROM student_visa_forms as svf;


/* Drop the old columns after the data has been migrated */
ALTER TABLE student_visa_forms 
    DROP COLUMN success_conditions, 
    DROP COLUMN reference;

/* Change the column name for all the elements fromt the previously called SelectableTextItem to SelectableItem */
ALTER TABLE student_visa_sst_training_items
    RENAME COLUMN text TO training_id;

ALTER TABLE student_visa_certificate_items
    RENAME COLUMN text TO certificate_type;

ALTER TABLE student_visa_skill_items
    RENAME COLUMN text TO skill_id;

ALTER TABLE student_visa_forces_items
    RENAME COLUMN text TO attitude_id;

ALTER TABLE student_visa_challenges_items
    RENAME COLUMN text TO attitude_id;

COMMIT;

/* Terminate the transaction */
END //
DELIMITER ;

