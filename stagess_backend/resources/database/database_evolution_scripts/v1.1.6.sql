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


/* Terminate the transaction */
COMMIT;
