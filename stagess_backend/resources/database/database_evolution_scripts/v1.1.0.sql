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
