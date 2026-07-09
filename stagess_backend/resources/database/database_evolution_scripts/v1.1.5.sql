/* Initialize the transaction */
START TRANSACTION;

/*********************/
/*** ADMIN SECTION ***/
/*********************/

ALTER TABLE teachers
    ADD COLUMN access_level INT NOT NULL DEFAULT 2;

UPDATE admins
    SET access_level = CASE access_level
        WHEN 3 THEN 4
        WHEN 4 THEN 5
        WHEN 5 THEN 6
    END
    WHERE access_level IN (3, 4, 5);


/* Terminate the transaction */
COMMIT;
