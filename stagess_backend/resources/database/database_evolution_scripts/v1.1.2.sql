/* Initialize the transaction */
START TRANSACTION;


/*********************/
/*** ADMIN SECTION ***/
/*********************/

ALTER TABLE admins 
    ADD COLUMN school_id VARCHAR(36) NOT NULL;
/* TODO: Change value of access_level */


/* Terminate the transaction */
COMMIT;

