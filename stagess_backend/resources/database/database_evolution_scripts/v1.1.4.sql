/* Initialize the transaction */
START TRANSACTION;

/*********************/
/*** ADMIN SECTION ***/
/*********************/

/* Just realized this column was 36 characters instead of 50 */
ALTER TABLE student_visa_references_items
    MODIFY COLUMN phone_number VARCHAR(50) NOT NULL;


/* Terminate the transaction */
COMMIT;
