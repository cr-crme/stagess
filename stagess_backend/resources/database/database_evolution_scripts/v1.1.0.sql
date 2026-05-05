/******************************/
/* Enterprises related tables */
/******************************/

UPDATE enterprises 
    SET website = '' 
    WHERE website IS NULL;

UPDATE enterprises
    SET neq = ''
    WHERE neq IS NULL;

ALTER TABLE enterprises
    MODIFY website VARCHAR(200) NOT NULL,
    MODIFY neq VARCHAR(50) NOT NULL;

DROP TABLE IF EXISTS enterprise_job_uniforms;
DROP TABLE IF EXISTS enterprise_job_protections;



/**************************/
/* Persons related tables */
/**************************/

UPDATE persons
    SET email = '' 
    WHERE email IS NULL;

ALTER TABLE persons
    MODIFY email VARCHAR(200) NOT NULL,
    DELETE middle_name;



/*************************/
/* Admins related tables */
/*************************/

INSERT INTO persons (id, first_name, last_name, email)
SELECT id, first_name, last_name, email
FROM admins;

ALTER TABLE admins
    DELETE first_name,
    DELETE middle_name,
    DELETE last_name,
    DELETE email;
