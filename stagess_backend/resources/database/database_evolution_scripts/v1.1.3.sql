/* Initialize the transaction */
START TRANSACTION;


/*********************/
/*** ADMIN SECTION ***/
/*********************/

ALTER TABLE internship_weekly_schedules
    ADD COLUMN cycle INT NOT NULL DEFAULT 0;

/* Terminate the transaction */
COMMIT;
