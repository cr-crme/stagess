/* Initialize the transaction */
START TRANSACTION;


/*********************/
/*** ADMIN SECTION ***/
/*********************/

ALTER TABLE admins 
    ADD COLUMN school_id VARCHAR(36) NOT NULL;
/* TODO: Change value of access_level */


/*******************/
/*** INTERNSHIPS SECTION ***/
/***************************/
ALTER TABLE internships
    DROP COLUMN school_board_id;
/* TODO ADD ON DELETE CASCADE for student_id to internships table */

/* Terminate the transaction */
COMMIT;

