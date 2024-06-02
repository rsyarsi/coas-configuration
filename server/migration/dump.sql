--
-- PostgreSQL database dump
--

-- Dumped from database version 14.11 (Debian 14.11-1.pgdg120+2)
-- Dumped by pg_dump version 14.12

-- Started on 2024-06-02 15:28:24 WIB

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 2 (class 3079 OID 16385)
-- Name: tablefunc; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS tablefunc WITH SCHEMA public;


--
-- TOC entry 3755 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION tablefunc; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION tablefunc IS 'functions that manipulate whole tables, including crosstab';


--
-- TOC entry 3 (class 3079 OID 16406)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 3756 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 296 (class 1255 OID 16417)
-- Name: generatefinal_konservasi(uuid, uuid, uuid); Type: PROCEDURE; Schema: public; Owner: rsyarsi
--

CREATE PROCEDURE public.generatefinal_konservasi(IN studentid uuid, IN semesterid uuid, IN yearid uuid)
    LANGUAGE plpgsql
    AS $$DECLARE
    student_id uuid;
    year_id uuid;
    semester_id uuid;
BEGIN
    student_id := studentid;
    year_id := yearid;
    semester_id := semesterid;

    CREATE TEMP TABLE IF NOT EXISTS TEMP_FINAL_KONSERVASI (
        nim varchar(50),
        name VARCHAR(250),
        kelompok VARCHAR(250),
        Tompatan_1 numeric,
        Tompatan_12 numeric,
        Tompatan_13 numeric,
        Tompatan_14 numeric,
        Tompatan_15 numeric,
        TOTAL numeric
    ) ON COMMIT DROP;

    INSERT INTO TEMP_FINAL_KONSERVASI
    SELECT
        b.nim,
        b.name,
        '' AS kelompok,
        SUM(CASE WHEN c.assementgroupname = 'TUMPATAN KOMPOSIT KLAS I' THEN a.assesmentfinalvalue ELSE 0 END) AS Tompatan_1,
        SUM(CASE WHEN c.assementgroupname = 'TUMPATAN KOMPOSIT KLAS II' THEN a.assesmentfinalvalue ELSE 0 END) AS Tompatan_12,
        SUM(CASE WHEN c.assementgroupname = 'TUMPATAN KOMPOSIT KLAS III' THEN a.assesmentfinalvalue ELSE 0 END) AS Tompatan_13,
        SUM(CASE WHEN c.assementgroupname = 'TUMPATAN KOMPOSIT KLAS IV' THEN a.assesmentfinalvalue ELSE 0 END) AS Tompatan_14,
        SUM(CASE WHEN c.assementgroupname = 'TUMPATAN KOMPOSIT KLAS V' THEN a.assesmentfinalvalue ELSE 0 END) AS Tompatan_15,
        SUM(
            CASE
                WHEN c.assementgroupname = 'TUMPATAN KOMPOSIT KLAS I' THEN a.assesmentfinalvalue
                WHEN c.assementgroupname = 'TUMPATAN KOMPOSIT KLAS II' THEN a.assesmentfinalvalue
                WHEN c.assementgroupname = 'TUMPATAN KOMPOSIT KLAS III' THEN a.assesmentfinalvalue
                WHEN c.assementgroupname = 'TUMPATAN KOMPOSIT KLAS IV' THEN a.assesmentfinalvalue
                WHEN c.assementgroupname = 'TUMPATAN KOMPOSIT KLAS V' THEN a.assesmentfinalvalue
                ELSE 0
            END
        ) AS TOTAL
    FROM
        trsassesments a 
    INNER JOIN
        students b ON a.studentid = b.id
    INNER JOIN
        assesmentgroups c ON c.id = a.assesmentgroupid
    WHERE
        a.specialistid = 'add71909-11e5-4adb-ab6e-919444d4aab7' 
        AND a.studentid = student_id 
        AND a.semesterid = semester_id 
        AND a.yearid = year_id
    GROUP BY
        b.nim, b.name;

	delete from finalassesment_konservasis
	where finalassesment_konservasis.studentid=student_id 
	and finalassesment_konservasis.semesterid=semester_id and finalassesment_konservasis.yearid=year_id;


    INSERT INTO finalassesment_konservasis (nim, name, kelompok,
                                            tumpatan_komposisi_1,
                                            tumpatan_komposisi_2,
                                            tumpatan_komposisi_3,
                                            tumpatan_komposisi_4,
                                            tumpatan_komposisi_5,
                                            totalakhir,
                                            grade,
                                            keterangan_grade,
                                            studentid,
                                            semesterid,
                                            yearid)
    SELECT
        nim,
        name,
        kelompok,
        Tompatan_1,
        Tompatan_12,
        Tompatan_13,
        Tompatan_14,
        Tompatan_15,
        TOTAL,
        CASE 
            WHEN TOTAL BETWEEN 0 AND 39.99 THEN 'E'
            WHEN TOTAL BETWEEN 40 AND 44.99 THEN 'D' 
            WHEN TOTAL BETWEEN 45 AND 49.99 THEN 'D+' 
            WHEN TOTAL BETWEEN 50 AND 52.49 THEN 'CD' 
            WHEN TOTAL BETWEEN 52.50 AND 54.99 THEN 'C-'
            WHEN TOTAL BETWEEN 55 AND 57.49 THEN 'C'
            WHEN TOTAL BETWEEN 57.50 AND 59.99 THEN 'C+'
            WHEN TOTAL BETWEEN 60 AND 62.49 THEN 'BC'
            WHEN TOTAL BETWEEN 62.50 AND 64.99 THEN 'B-'
            WHEN TOTAL BETWEEN 65 AND 67.49 THEN 'B'
            WHEN TOTAL BETWEEN 67.50 AND 69.99 THEN 'B+'
            WHEN TOTAL BETWEEN 70 AND 72.49 THEN 'AB'
            WHEN TOTAL BETWEEN 72.50 AND 74.99 THEN 'A-'
            WHEN TOTAL >= 75 THEN 'A'
        END AS huruf,
        '',
        student_id,
        semester_id,
        year_id 
    FROM
        TEMP_FINAL_KONSERVASI;
END;$$;


ALTER PROCEDURE public.generatefinal_konservasi(IN studentid uuid, IN semesterid uuid, IN yearid uuid) OWNER TO rsyarsi;

--
-- TOC entry 297 (class 1255 OID 16418)
-- Name: generatefinal_orthodonti(uuid, uuid, uuid); Type: PROCEDURE; Schema: public; Owner: rsyarsi
--

CREATE PROCEDURE public.generatefinal_orthodonti(IN studentid uuid, IN semesterid uuid, IN yearid uuid)
    LANGUAGE plpgsql
    AS $$DECLARE
	idsubfinalhdr uuid;
	totalpekerjaanklinik numeric;
	bobotpekerjaanklinik numeric;
	fixpekerjaanklinik numeric;
	totallaporankasus numeric;
	bobotlaporankasus numeric;
	fixlaporankasus numeric;
	student_id uuid;
	year_id uuid;
	semester_id uuid;
begin
	student_id := studentid;
	year_id := yearid;
	semester_id := semesterid;
    	
     CREATE TEMP TABLE IF NOT EXISTS TEMP_FINAL_ORTHO (nim varchar(50), name VARCHAR(250), 
								 kelompok VARCHAR(250),
								anamnesis numeric,foto_oi numeric,
							     cetak_rahang numeric,modelstudi_one numeric,analisismodel numeric,analisissefalometri numeric,
							     fotografi_oral numeric,rencana_perawatan numeric,insersi_alat numeric,
							     aktivasi_alat numeric,kontrol numeric,
								model_studi_2 numeric,
								penilaian_hasil_perawatan numeric,
								laporan_khusus numeric, 
								 TOTAL numeric) ON COMMIT DROP;
								 
	INSERT INTO TEMP_FINAL_ORTHO
	select b.nim, b.name,'' as kelompok, 
 SUM(CASE WHEN c.assementgroupname = 'ANAMNESIS' THEN a.assesmentfinalvalue ELSE '0' END) AS anamnesis,
 SUM(CASE WHEN c.assementgroupname = 'PEMERIKSAAN EO DAN IO, FOTO WAJAH DAN FOTO IO' THEN a.assesmentfinalvalue ELSE '0' END) AS foto_oi,
 SUM(CASE WHEN c.assementgroupname = 'MENCETAK RAHANG ATAS DAN MENCETAK RAHANG BAWAH' THEN a.assesmentfinalvalue ELSE '0' END) AS cetak_rahang,
 SUM(CASE WHEN c.assementgroupname = 'MEMBUAT MODEL STUDI 1 DAN MODEL KERJA' THEN a.assesmentfinalvalue ELSE '0' END) AS modelstudi_one,
 SUM(CASE WHEN c.assementgroupname = 'ANALISIS MODEL' THEN a.assesmentfinalvalue ELSE '0' END) AS analisismodel,
 SUM(CASE WHEN c.assementgroupname = 'ANALISIS SEFALOMETRI' THEN a.assesmentfinalvalue ELSE '0' END) AS analisissefalometri,
 SUM(CASE WHEN c.assementgroupname = 'FOTOGRAFI EKSTRA ORAL DAN INTRA ORAL' THEN a.assesmentfinalvalue ELSE '0' END) AS fotografi_oral,
 SUM(CASE WHEN c.assementgroupname = 'DIAGNOSIS, ETIOLOGI DAN RENCANA PERAWATAN' THEN a.assesmentfinalvalue ELSE '0' END) AS rencana_perawatan,
 SUM(CASE WHEN c.assementgroupname = 'INSERSI ALAT ORTODONTI LEPASAN' THEN a.assesmentfinalvalue ELSE '0' END) AS insersi_alat,
 SUM(CASE WHEN c.assementgroupname = 'AKTIVASI ALAT ORTODONTI' THEN a.assesmentfinalvalue ELSE '0' END) AS aktivasi_alat,
 SUM(CASE WHEN c.assementgroupname = 'KONTROL' THEN a.assesmentfinalvalue ELSE '0' END) AS kontrol,
 SUM(CASE WHEN c.assementgroupname = 'MODEL STUDI 2' THEN a.assesmentfinalvalue ELSE '0' END) AS model_studi_2,
 SUM(CASE WHEN c.assementgroupname = 'PENILAIAN HASIL PERAWATAN' THEN a.assesmentfinalvalue ELSE '0' END) AS penilaian_hasil_perawatan,
 SUM(CASE WHEN c.assementgroupname = 'PENYAJI LAPORAN KASUS' THEN a.assesmentfinalvalue ELSE '0' END) AS laporan_khusus, 
 SUM(CASE WHEN c.assementgroupname = 'ANAMNESIS' THEN a.assesmentfinalvalue ELSE '0' END) +
 SUM(CASE WHEN c.assementgroupname = 'PEMERIKSAAN EO DAN IO, FOTO WAJAH DAN FOTO IO' THEN a.assesmentfinalvalue ELSE '0' END) +
 SUM(CASE WHEN c.assementgroupname = 'MENCETAK RAHANG ATAS DAN MENCETAK RAHANG BAWAH' THEN a.assesmentfinalvalue ELSE '0' END) +
 SUM(CASE WHEN c.assementgroupname = 'MEMBUAT MODEL STUDI 1 DAN MODEL KERJA' THEN a.assesmentfinalvalue ELSE '0' END) +
 SUM(CASE WHEN c.assementgroupname = 'ANALISIS MODEL' THEN a.assesmentfinalvalue ELSE '0' END) +
 SUM(CASE WHEN c.assementgroupname = 'ANALISIS SEFALOMETRI' THEN a.assesmentfinalvalue ELSE '0' END) +
 SUM(CASE WHEN c.assementgroupname = 'FOTOGRAFI EKSTRA ORAL DAN INTRA ORAL' THEN a.assesmentfinalvalue ELSE '0' END)+
 SUM(CASE WHEN c.assementgroupname = 'DIAGNOSIS, ETIOLOGI DAN RENCANA PERAWATAN' THEN a.assesmentfinalvalue ELSE '0' END) +
 SUM(CASE WHEN c.assementgroupname = 'INSERSI ALAT ORTODONTI LEPASAN' THEN a.assesmentfinalvalue ELSE '0' END)+
 SUM(CASE WHEN c.assementgroupname = 'AKTIVASI ALAT ORTODONTI' THEN a.assesmentfinalvalue ELSE '0' END)+
 SUM(CASE WHEN c.assementgroupname = 'KONTROL' THEN a.assesmentfinalvalue ELSE '0' END) +
 SUM(CASE WHEN c.assementgroupname = 'MODEL STUDI 2' THEN a.assesmentfinalvalue ELSE '0' END) +
 SUM(CASE WHEN c.assementgroupname = 'PENILAIAN HASIL PERAWATAN' THEN a.assesmentfinalvalue ELSE '0' END) +
 SUM(CASE WHEN c.assementgroupname = 'PENYAJI LAPORAN KASUS' THEN a.assesmentfinalvalue ELSE '0' END)  AS TOTAL
 from trsassesments a 
	inner join students b
	on a.studentid = b.id
	inner join assesmentgroups c
	on c.id = a.assesmentgroupid
	where a.specialistid='4b5ca39c-5a37-46d1-8198-3fe2202775a2' and a.studentid=student_id and a.semesterid=semester_id and a.yearid=year_id
	group by b.nim, b.name;


-- CARI TOTAL PEKERJAAN KLINIK
totalpekerjaanklinik = (select anamnesis+foto_oi+cetak_rahang+modelstudi_one+analisismodel+analisissefalometri+fotografi_oral+rencana_perawatan+insersi_alat+aktivasi_alat+kontrol+model_studi_2+penilaian_hasil_perawatan from TEMP_FINAL_ORTHO );
	
-- cari bobot pekerjaan klinik
bobotpekerjaanklinik = (SELECT bobotvaluefinal FROM assesmentgroupfinals where specialistid='4b5ca39c-5a37-46d1-8198-3fe2202775a2' and name='PEKERJAAN KLINIK - ORTHO');

-- HITUNG NILAI PEKERJAAN KLINIK 
fixpekerjaanklinik = (totalpekerjaanklinik*bobotpekerjaanklinik)/100;


-- CARI TOTAL laporan KHUSUS
totallaporankasus = (select laporan_khusus from TEMP_FINAL_ORTHO);
-- cari bobot laporan KHUSUS
bobotlaporankasus = (SELECT bobotvaluefinal FROM assesmentgroupfinals where specialistid='4b5ca39c-5a37-46d1-8198-3fe2202775a2' and name='LAPORAN KASUS - ORTHO');

fixlaporankasus = (totallaporankasus*bobotlaporankasus)/100;

delete from finalassesment_orthodonties
	where finalassesment_orthodonties.studentid=student_id 
	and finalassesment_orthodonties.semesterid=semester_id and finalassesment_orthodonties.yearid=year_id;

	insert into finalassesment_orthodonties (nim,name,kelompok,
											anamnesis,
											foto_oi,
											cetak_rahang,
											modelstudi_one,
											analisismodel,
											analisissefalometri,
											fotografi_oral,
											rencana_perawatan,
											insersi_alat,
											aktivasi_alat,
											kontrol,
											model_studi_2,
											penilaian_hasil_perawatan,
											laporan_khusus, 
											totalakhir,
											grade,
											keterangan_grade,
											 nilaipekerjaanklinik,
											 nilailaporankasus
											 ,studentid
											 ,semesterid
											 ,yearid
											)
	 select nim , name , kelompok,
	 anamnesis,
	 foto_oi,
	 cetak_rahang,
	 modelstudi_one,
	 analisismodel,
	 analisissefalometri,
	 fotografi_oral,
	 rencana_perawatan,
	 insersi_alat,
	 aktivasi_alat,
	 kontrol,
	 model_studi_2,
	 penilaian_hasil_perawatan,
	 laporan_khusus, 
	TOTAL, 
	CASE 
		WHEN TOTAL >0 and TOTAL <40 then 'E'
		WHEN TOTAL >=40.00 and TOTAL <=44.99 then 'D' 
		WHEN TOTAL >=45.00 and TOTAL <=49.99 then 'D+' 
		WHEN TOTAL >=50.00 and TOTAL <=52.49 then 'CD' 
		WHEN TOTAL >=52.50 and TOTAL <=54.99 then 'C-'
		WHEN TOTAL >=55.00 and TOTAL <=57.49 then 'C'
		WHEN TOTAL >=57.50 and TOTAL <=59.99 then 'C+'
		WHEN TOTAL >=60.00 and TOTAL <=62.49 then 'BC'
		WHEN TOTAL >=62.50 and TOTAL <=64.99 then 'B-'
		WHEN TOTAL >=65.00 and TOTAL <=67.49 then 'B'
		WHEN TOTAL >=67.50 and TOTAL <=69.99 then 'B+'
		WHEN TOTAL >=70.00 and TOTAL <=72.49 then 'AB'
		WHEN TOTAL >=72.50 and TOTAL <=74.99 then 'A-'
		WHEN TOTAL >=75   then 'A'
	END AS huruf,'',fixpekerjaanklinik ,fixlaporankasus 
											,studentid
											 ,semesterid
											 ,yearid from TEMP_FINAL_ORTHO;

    --commit;
end;$$;


ALTER PROCEDURE public.generatefinal_orthodonti(IN studentid uuid, IN semesterid uuid, IN yearid uuid) OWNER TO rsyarsi;

--
-- TOC entry 306 (class 1255 OID 16420)
-- Name: generatefinal_periodonties(uuid, uuid, uuid); Type: PROCEDURE; Schema: public; Owner: rsyarsi
--

CREATE PROCEDURE public.generatefinal_periodonties(IN studentid uuid, IN semesterid uuid, IN yearid uuid)
    LANGUAGE plpgsql
    AS $$declare
	student_id uuid;
	year_id uuid;
	semester_id uuid;

begin
	student_id := studentid;
	year_id := yearid;
	semester_id := semesterid;
 
  CREATE TEMP TABLE IF NOT EXISTS TEMP_FINAL_PERIO (nim varchar(50), name VARCHAR(250), 
								 kelompok VARCHAR(250),
								anamnesis_scalingmanual numeric,
								anamnesis_uss numeric,
							     uss_desensitisasi numeric,
							     splinting_fiber numeric,
							     diskusi_tatapmuka numeric,
							     dops numeric,
								 TOTAL numeric) ON COMMIT DROP;
								 
	INSERT INTO TEMP_FINAL_PERIO
		select b.nim, b.name,'' as kelompok, 
 SUM(CASE WHEN c.assementgroupname = 'Anamnesis dan Pengisian Status+ Scaling manual+kontrol' THEN a.assesmentfinalvalue ELSE '0' END) AS anamnesis_scalingmanual,
 SUM(CASE WHEN c.assementgroupname = 'Anamnesis dan Pengisian Status+ USS+kontrol' THEN a.assesmentfinalvalue ELSE '0' END) AS anamnesis_uss,
 SUM(CASE WHEN c.assementgroupname = 'USS+kontrol+ desensitisasi+kontrol' THEN a.assesmentfinalvalue ELSE '0' END) AS uss_desensitisasi,
 SUM(CASE WHEN c.assementgroupname = 'Splinting fiber' THEN a.assesmentfinalvalue ELSE '0' END) AS splinting_fiber,
 SUM(CASE WHEN c.assementgroupname = 'Diskusi Tatap Muka/penyaji diskusi (Kasus Desentisisasi)' THEN a.assesmentfinalvalue ELSE '0' END) AS diskusi_tatapmuka,
 SUM(CASE WHEN c.assementgroupname = 'DOPS scaling manual + kontrol' THEN a.assesmentfinalvalue ELSE '0' END) AS dops,
 SUM(CASE WHEN c.assementgroupname = 'Anamnesis dan Pengisian Status+ Scaling manual+kontrol' THEN a.assesmentfinalvalue ELSE '0' END) +
 SUM(CASE WHEN c.assementgroupname = 'Anamnesis dan Pengisian Status+ USS+kontrol' THEN a.assesmentfinalvalue ELSE '0' END) +
 SUM(CASE WHEN c.assementgroupname = 'USS+kontrol+ desensitisasi+kontrol' THEN a.assesmentfinalvalue ELSE '0' END) +
 SUM(CASE WHEN c.assementgroupname = 'Splinting fiber' THEN a.assesmentfinalvalue ELSE '0' END) +
 SUM(CASE WHEN c.assementgroupname = 'Diskusi Tatap Muka/penyaji diskusi (Kasus Desentisisasi)' THEN a.assesmentfinalvalue ELSE '0' END) +
 SUM(CASE WHEN c.assementgroupname = 'DOPS scaling manual + kontrol' THEN a.assesmentfinalvalue ELSE '0' END)   AS TOTAL
 from trsassesments a 
	inner join students b
	on a.studentid = b.id
	inner join assesmentgroups c
	on c.id = a.assesmentgroupid
	where a.specialistid='88e2a725-abb3-459d-99dc-69a43a39d504' and a.studentid=student_id and a.semesterid=semester_id and a.yearid=year_id
	group by b.nim, b.name;

delete from finalassesment_periodonties
	where finalassesment_periodonties.studentid=student_id 
	and finalassesment_periodonties.semesterid=semester_id and finalassesment_periodonties.yearid=year_id;
	

	 insert into finalassesment_periodonties (nim,name,kelompok,
											anamnesis_scalingmanual,
											anamnesis_uss,
											uss_desensitisasi,
											splinting_fiber,
											diskusi_tatapmuka,
											dops, 
											totalakhir,
											grade,
											keterangan_grade
											  ,studentid
											 ,semesterid
											 ,yearid)
	 select nim , name , kelompok,
		anamnesis_scalingmanual,
	anamnesis_uss,
	uss_desensitisasi,
	splinting_fiber,
	diskusi_tatapmuka,
	dops,
	TOTAL, 
	CASE 
		WHEN TOTAL >0 and TOTAL <40 then 'E'
		WHEN TOTAL >=40.00 and TOTAL <=44.99 then 'D' 
		WHEN TOTAL >=45.00 and TOTAL <=49.99 then 'D+' 
		WHEN TOTAL >=50.00 and TOTAL <=52.49 then 'CD' 
		WHEN TOTAL >=52.50 and TOTAL <=54.99 then 'C-'
		WHEN TOTAL >=55.00 and TOTAL <=57.49 then 'C'
		WHEN TOTAL >=57.50 and TOTAL <=59.99 then 'C+'
		WHEN TOTAL >=60.00 and TOTAL <=62.49 then 'BC'
		WHEN TOTAL >=62.50 and TOTAL <=64.99 then 'B-'
		WHEN TOTAL >=65.00 and TOTAL <=67.49 then 'B'
		WHEN TOTAL >=67.50 and TOTAL <=69.99 then 'B+'
		WHEN TOTAL >=70.00 and TOTAL <=72.49 then 'AB'
		WHEN TOTAL >=72.50 and TOTAL <=74.99 then 'A-'
		WHEN TOTAL >=75   then 'A'
	END AS huruf,''
	 ,studentid
	 ,semesterid
	 ,yearid 
											 from TEMP_FINAL_PERIO;
	
 
    --commit;
end;
$$;


ALTER PROCEDURE public.generatefinal_periodonties(IN studentid uuid, IN semesterid uuid, IN yearid uuid) OWNER TO rsyarsi;

--
-- TOC entry 307 (class 1255 OID 16421)
-- Name: generatefinal_prostodonti(uuid, uuid, uuid); Type: PROCEDURE; Schema: public; Owner: rsyarsi
--

CREATE PROCEDURE public.generatefinal_prostodonti(IN studentid uuid, IN semesterid uuid, IN yearid uuid)
    LANGUAGE plpgsql
    AS $$declare
	student_id uuid;
	year_id uuid;
	semester_id uuid;
begin
	student_id := studentid;
	year_id := yearid;
	semester_id := semesterid;
 
  CREATE TEMP TABLE IF NOT EXISTS TEMP_FINAL_PROSTO (nim varchar(50), name VARCHAR(250), 
								 kelompok VARCHAR(250),
								penyajian_diskusi numeric,
								gigi_tiruan_lepas numeric,
							     dops_fungsional numeric,
								 TOTAL numeric) ON COMMIT DROP;
								 
	INSERT INTO TEMP_FINAL_PROSTO
		select b.nim, b.name,'' as kelompok, 
 SUM(CASE WHEN c.assementgroupname = 'PENYAJI DISKUSI KASUS GIGI TIRUAN SEBAGIAN LEPASAN' THEN a.assesmentfinalvalue ELSE '0' END) AS penyajian_diskusi,
 SUM(CASE WHEN c.assementgroupname = 'Gigi Tiruan Sebagian Lepasan' THEN a.assesmentfinalvalue ELSE '0' END) AS gigi_tiruan_lepas,
 SUM(CASE WHEN c.assementgroupname = 'DOPS MENCETAK FUNGSIONAL' THEN a.assesmentfinalvalue ELSE '0' END) AS dops_fungsional,
  SUM(CASE WHEN c.assementgroupname = 'PENYAJI DISKUSI KASUS GIGI TIRUAN SEBAGIAN LEPASAN' THEN a.assesmentfinalvalue ELSE '0' END)+
 SUM(CASE WHEN c.assementgroupname = 'Gigi Tiruan Sebagian Lepasan' THEN a.assesmentfinalvalue ELSE '0' END)+
 SUM(CASE WHEN c.assementgroupname = 'DOPS MENCETAK FUNGSIONAL' THEN a.assesmentfinalvalue ELSE '0' END) AS TOTAL
 from trsassesments a 
	inner join students b
	on a.studentid = b.id
	inner join assesmentgroups c
	on c.id = a.assesmentgroupid
	where a.specialistid='a89710d5-0c4c-4823-9932-18ce001d71a5' and a.studentid=student_id and a.semesterid=semester_id and a.yearid=year_id
	group by b.nim, b.name;

	delete from finalassesment_prostodonties
	where finalassesment_prostodonties.studentid=student_id 
	and finalassesment_prostodonties.semesterid=semester_id and finalassesment_prostodonties.yearid=year_id;

	 insert into finalassesment_prostodonties (nim,name,kelompok,
											penyajian_diskusi,
											gigi_tiruan_lepas,
											dops_fungsional, 
											totalakhir,
											grade,
											keterangan_grade
											    ,studentid
											 ,semesterid
											 ,yearid
											  )
	 select nim , name , kelompok,
	 penyajian_diskusi,
	 gigi_tiruan_lepas,
	 dops_fungsional, 
	TOTAL, 
	CASE 
		WHEN TOTAL >0 and TOTAL <40 then 'E'
		WHEN TOTAL >=40.00 and TOTAL <=44.99 then 'D' 
		WHEN TOTAL >=45.00 and TOTAL <=49.99 then 'D+' 
		WHEN TOTAL >=50.00 and TOTAL <=52.49 then 'CD' 
		WHEN TOTAL >=52.50 and TOTAL <=54.99 then 'C-'
		WHEN TOTAL >=55.00 and TOTAL <=57.49 then 'C'
		WHEN TOTAL >=57.50 and TOTAL <=59.99 then 'C+'
		WHEN TOTAL >=60.00 and TOTAL <=62.49 then 'BC'
		WHEN TOTAL >=62.50 and TOTAL <=64.99 then 'B-'
		WHEN TOTAL >=65.00 and TOTAL <=67.49 then 'B'
		WHEN TOTAL >=67.50 and TOTAL <=69.99 then 'B+'
		WHEN TOTAL >=70.00 and TOTAL <=72.49 then 'AB'
		WHEN TOTAL >=72.50 and TOTAL <=74.99 then 'A-'
		WHEN TOTAL >=75   then 'A'
	END AS huruf,'' ,studentid
											 ,semesterid
											 ,yearid from TEMP_FINAL_PROSTO;
 
    --commit;
end;$$;


ALTER PROCEDURE public.generatefinal_prostodonti(IN studentid uuid, IN semesterid uuid, IN yearid uuid) OWNER TO rsyarsi;

--
-- TOC entry 308 (class 1255 OID 16422)
-- Name: generatefinal_radiologi(uuid, uuid, uuid); Type: PROCEDURE; Schema: public; Owner: rsyarsi
--

CREATE PROCEDURE public.generatefinal_radiologi(IN studentid uuid, IN semesterid uuid, IN yearid uuid)
    LANGUAGE plpgsql
    AS $$
declare
	student_id uuid;
	year_id uuid;
	semester_id uuid;

begin
	student_id := studentid;
	year_id := yearid;
	semester_id := semesterid;
 
  CREATE TEMP TABLE IF NOT EXISTS TEMP_FINAL_RADIOLOGI (nim varchar(50), name VARCHAR(250), 
								 kelompok VARCHAR(250),
								videoteknikradiografi_periapikalbisektris numeric,
								videoteknikradiografi_oklusal numeric,
								interpretasi_foto_periapikal numeric,
								interpretasi_foto_panoramik numeric,
								interpretasi_foto_oklusal numeric,
								rujukan_medik numeric,
								penyaji_jr numeric,
								dops numeric,
								ujian_bagian numeric,
								 TOTAL numeric) ON COMMIT DROP;
								 
	INSERT INTO TEMP_FINAL_RADIOLOGI
		select b.nim, b.name,'' as kelompok, 
 SUM(CASE WHEN c.assementgroupname = 'VIDEO TEKNIK RADIOGRAFI INTRAORAL PERIAPIKAL' THEN a.assesmentfinalvalue ELSE '0' END) AS videoteknikradiografi_periapikalbisektris,
 SUM(CASE WHEN c.assementgroupname = 'VIDEO TEKNIK RADIOGRAFI INTRAORAL OKLUSAL' THEN a.assesmentfinalvalue ELSE '0' END) AS videoteknikradiografi_oklusal,
 SUM(CASE WHEN c.assementgroupname = 'TEKNIK RADIOGRAFI INTRAORAL PERIAPIKAL' 
	 --OR c.assementgroupname = 'Radiografi Intraoral Periapikal' 
	 THEN a.assesmentfinalvalue ELSE '0' END) AS interpretasi_foto_periapikal,
 SUM(CASE WHEN c.assementgroupname = 'LEMBAR  INTERPRETASI EKSTRAORAL' THEN a.assesmentfinalvalue ELSE '0' END) AS interpretasi_foto_panoramik,
 SUM(CASE WHEN c.assementgroupname = 'INTERPRETASI RADIOGRAF OKLUSAL' THEN a.assesmentfinalvalue ELSE '0' END) AS interpretasi_foto_oklusal,
 SUM(CASE WHEN c.assementgroupname = 'PENILAIAN PROSESING FILM RONGTEN DIGITAL' THEN a.assesmentfinalvalue ELSE '0' END) AS rujukan_medik,--?
 SUM(CASE WHEN c.assementgroupname = 'PENYAJI JR' THEN a.assesmentfinalvalue ELSE '0' END) AS penyaji_jr,
 SUM(CASE WHEN c.assementgroupname = 'DOPS' THEN a.assesmentfinalvalue ELSE '0' END) AS dops,
 SUM(CASE WHEN c.assementgroupname = 'INTERPRETASI RADIOGRAF INTRAORAL' THEN a.assesmentfinalvalue ELSE '0' END) AS ujian_bagian,--?
 
 SUM(CASE WHEN c.assementgroupname = 'VIDEO TEKNIK RADIOGRAFI INTRAORAL PERIAPIKAL' THEN a.assesmentfinalvalue ELSE '0' END)  +
 SUM(CASE WHEN c.assementgroupname = 'VIDEO TEKNIK RADIOGRAFI INTRAORAL OKLUSAL' THEN a.assesmentfinalvalue ELSE '0' END)  +
 SUM(CASE WHEN c.assementgroupname = 'TEKNIK RADIOGRAFI INTRAORAL PERIAPIKAL' 
	 --OR c.assementgroupname = 'Radiografi Intraoral Periapikal' 
	 THEN a.assesmentfinalvalue ELSE '0' END)  +
 SUM(CASE WHEN c.assementgroupname = 'LEMBAR  INTERPRETASI EKSTRAORAL' THEN a.assesmentfinalvalue ELSE '0' END)  +
 SUM(CASE WHEN c.assementgroupname = 'INTERPRETASI RADIOGRAF OKLUSAL' THEN a.assesmentfinalvalue ELSE '0' END)  +
 SUM(CASE WHEN c.assementgroupname = 'PENILAIAN PROSESING FILM RONGTEN DIGITAL' THEN a.assesmentfinalvalue ELSE '0' END)  +
 SUM(CASE WHEN c.assementgroupname = 'PENYAJI JR' THEN a.assesmentfinalvalue ELSE '0' END)  +
 SUM(CASE WHEN c.assementgroupname = 'DOPS' THEN a.assesmentfinalvalue ELSE '0' END)  +
 SUM(CASE WHEN c.assementgroupname = 'INTERPRETASI RADIOGRAF INTRAORAL' THEN a.assesmentfinalvalue ELSE '0' END)    AS TOTAL
 from trsassesments a 
	inner join students b
	on a.studentid = b.id
	inner join assesmentgroups c
	on c.id = a.assesmentgroupid
	where a.specialistid='cf504bf3-803c-432c-afe1-d718824359d5' and a.studentid=student_id and a.semesterid=semester_id and a.yearid=year_id
	group by b.nim, b.name;
	
	delete from finalassesment_radiologies
	where finalassesment_radiologies.studentid=student_id 
	and finalassesment_radiologies.semesterid=semester_id and finalassesment_radiologies.yearid=year_id;
	

	 insert into finalassesment_radiologies (nim,name,kelompok,
	 										videoteknikradiografi_periapikalbisektris,
											videoteknikradiografi_oklusal,
											interpretasi_foto_periapikal,
											interpretasi_foto_panoramik,
											interpretasi_foto_oklusal,
											rujukan_medik,
											penyaji_jr,
											dops,
											ujian_bagian,
											totalakhir,
											grade,
											keterangan_grade
											  ,studentid
											 ,semesterid
											 ,yearid)
	 select nim , name , kelompok,
		videoteknikradiografi_periapikalbisektris,
		videoteknikradiografi_oklusal,
		interpretasi_foto_periapikal,
		interpretasi_foto_panoramik,
		interpretasi_foto_oklusal,
		rujukan_medik,
		penyaji_jr,
		dops,
		ujian_bagian,
	TOTAL, 
	CASE 
		WHEN TOTAL >0 and TOTAL <40 then 'E'
		WHEN TOTAL >=40.00 and TOTAL <=44.99 then 'D' 
		WHEN TOTAL >=45.00 and TOTAL <=49.99 then 'D+' 
		WHEN TOTAL >=50.00 and TOTAL <=52.49 then 'CD' 
		WHEN TOTAL >=52.50 and TOTAL <=54.99 then 'C-'
		WHEN TOTAL >=55.00 and TOTAL <=57.49 then 'C'
		WHEN TOTAL >=57.50 and TOTAL <=59.99 then 'C+'
		WHEN TOTAL >=60.00 and TOTAL <=62.49 then 'BC'
		WHEN TOTAL >=62.50 and TOTAL <=64.99 then 'B-'
		WHEN TOTAL >=65.00 and TOTAL <=67.49 then 'B'
		WHEN TOTAL >=67.50 and TOTAL <=69.99 then 'B+'
		WHEN TOTAL >=70.00 and TOTAL <=72.49 then 'AB'
		WHEN TOTAL >=72.50 and TOTAL <=74.99 then 'A-'
		WHEN TOTAL >=75   then 'A'
	END AS huruf,''
	 ,studentid
	 ,semesterid
	 ,yearid 
											 from TEMP_FINAL_RADIOLOGI;
	
 
    --commit;
end;
$$;


ALTER PROCEDURE public.generatefinal_radiologi(IN studentid uuid, IN semesterid uuid, IN yearid uuid) OWNER TO rsyarsi;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 214 (class 1259 OID 16423)
-- Name: absencestudents; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.absencestudents (
    id uuid NOT NULL,
    studentid uuid,
    time_in timestamp without time zone,
    time_out timestamp without time zone,
    date date,
    statusabsensi character varying(5),
    updated_at timestamp without time zone,
    created_at timestamp without time zone,
    periode character varying(7)
);


ALTER TABLE public.absencestudents OWNER TO rsyarsi;

--
-- TOC entry 215 (class 1259 OID 16426)
-- Name: assesmentdetails; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.assesmentdetails (
    id uuid NOT NULL,
    assesmentgroupid uuid NOT NULL,
    assesmentnumbers integer NOT NULL,
    assesmentdescription text NOT NULL,
    assesmentbobotvalue integer NOT NULL,
    assesmentskalavalue text NOT NULL,
    assesmentskalavaluestart integer NOT NULL,
    assesmentskalavalueend integer NOT NULL,
    assesmentkonditevalue text NOT NULL,
    assesmentkonditevaluestart integer NOT NULL,
    assesmentkonditevalueend integer NOT NULL,
    active integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    assesmentvaluestart integer,
    assesmentvalueend integer,
    kodesub integer DEFAULT 0,
    index_sub integer DEFAULT 0,
    kode_sub_name text
);


ALTER TABLE public.assesmentdetails OWNER TO rsyarsi;

--
-- TOC entry 216 (class 1259 OID 16433)
-- Name: assesmentgroupfinals; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.assesmentgroupfinals (
    id uuid NOT NULL,
    name text,
    active integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    specialistid uuid,
    bobotvaluefinal numeric
);


ALTER TABLE public.assesmentgroupfinals OWNER TO rsyarsi;

--
-- TOC entry 217 (class 1259 OID 16438)
-- Name: assesmentgroups; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.assesmentgroups (
    id uuid NOT NULL,
    specialistid uuid NOT NULL,
    assementgroupname text NOT NULL,
    type integer NOT NULL,
    active integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    valuetotal integer,
    isskala integer DEFAULT 0,
    idassesmentgroupfinal uuid,
    bobotprosenfinal bigint
);


ALTER TABLE public.assesmentgroups OWNER TO rsyarsi;

--
-- TOC entry 218 (class 1259 OID 16444)
-- Name: emrkonservasi_jobs; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.emrkonservasi_jobs (
    id uuid NOT NULL,
    datejob timestamp without time zone,
    keadaangigi text,
    tindakan text,
    keterangan text,
    user_entry character varying(150),
    user_entry_name character varying(255),
    user_verify character varying(150),
    user_verify_name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    idemr uuid,
    active integer DEFAULT 1,
    date_verify timestamp without time zone
);


ALTER TABLE public.emrkonservasi_jobs OWNER TO rsyarsi;

--
-- TOC entry 219 (class 1259 OID 16450)
-- Name: emrkonservasis; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.emrkonservasis (
    id uuid NOT NULL,
    noregister character varying(25),
    noepisode character varying(25),
    nomorrekammedik character varying(25),
    tanggal timestamp(6) without time zone,
    namapasien character varying(225),
    pekerjaan character varying(225),
    jeniskelamin character varying(25),
    alamatpasien character varying(350),
    nomortelpon character varying(25),
    namaoperator character varying(225),
    nim character varying(25),
    sblmperawatanpemeriksaangigi_18_tv character varying(25),
    sblmperawatanpemeriksaangigi_17_tv character varying(25),
    sblmperawatanpemeriksaangigi_16_tv character varying(25),
    sblmperawatanpemeriksaangigi_15_55_tv character varying(25),
    sblmperawatanpemeriksaangigi_14_54_tv character varying(25),
    sblmperawatanpemeriksaangigi_13_53_tv character varying(25),
    sblmperawatanpemeriksaangigi_12_52_tv character varying(25),
    sblmperawatanpemeriksaangigi_11_51_tv character varying(25),
    sblmperawatanpemeriksaangigi_21_61_tv character varying(25),
    sblmperawatanpemeriksaangigi_22_62_tv character varying(25),
    sblmperawatanpemeriksaangigi_23_63_tv character varying(25),
    sblmperawatanpemeriksaangigi_24_64_tv character varying(25),
    sblmperawatanpemeriksaangigi_25_65_tv character varying(25),
    sblmperawatanpemeriksaangigi_26_tv character varying(25),
    sblmperawatanpemeriksaangigi_27_tv character varying(25),
    sblmperawatanpemeriksaangigi_28_tv character varying(25),
    sblmperawatanpemeriksaangigi_18_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_17_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_16_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_15_55_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_14_54_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_13_53_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_12_52_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_11_51_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_21_61_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_22_62_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_23_63_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_24_64_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_25_65_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_26_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_27_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_28_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_18_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_17_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_16_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_15_55_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_14_54_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_13_53_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_12_52_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_11_51_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_21_61_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_22_62_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_23_63_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_24_64_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_25_65_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_26_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_27_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_28_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_41_81_tv character varying(25),
    sblmperawatanpemeriksaangigi_42_82_tv character varying(25),
    sblmperawatanpemeriksaangigi_43_83_tv character varying(25),
    sblmperawatanpemeriksaangigi_44_84_tv character varying(25),
    sblmperawatanpemeriksaangigi_45_85_tv character varying(25),
    sblmperawatanpemeriksaangigi_46_tv character varying(25),
    sblmperawatanpemeriksaangigi_47_tv character varying(25),
    sblmperawatanpemeriksaangigi_48_tv character varying(25),
    sblmperawatanpemeriksaangigi_38_tv character varying(25),
    sblmperawatanpemeriksaangigi_37_tv character varying(25),
    sblmperawatanpemeriksaangigi_36_tv character varying(25),
    sblmperawatanpemeriksaangigi_35_75_tv character varying(25),
    sblmperawatanpemeriksaangigi_34_74_tv character varying(25),
    sblmperawatanpemeriksaangigi_33_73_tv character varying(25),
    sblmperawatanpemeriksaangigi_32_72_tv character varying(25),
    sblmperawatanpemeriksaangigi_31_71_tv character varying(25),
    sblmperawatanpemeriksaangigi_41_81_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_42_82_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_43_83_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_44_84_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_45_85_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_46_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_47_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_48_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_38_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_37_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_36_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_35_75_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_34_74_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_33_73_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_32_72_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_31_71_diagnosis character varying(25),
    sblmperawatanpemeriksaangigi_41_81_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_42_82_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_43_83_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_44_84_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_45_85_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_46_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_47_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_48_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_38_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_37_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_36_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_35_75_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_34_74_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_33_73_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_32_72_rencanaperawatan character varying(25),
    sblmperawatanpemeriksaangigi_31_71_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_18_tv character varying(25),
    ssdhperawatanpemeriksaangigi_17_tv character varying(25),
    ssdhperawatanpemeriksaangigi_16_tv character varying(25),
    ssdhperawatanpemeriksaangigi_15_55_tv character varying(25),
    ssdhperawatanpemeriksaangigi_14_54_tv character varying(25),
    ssdhperawatanpemeriksaangigi_13_53_tv character varying(25),
    ssdhperawatanpemeriksaangigi_12_52_tv character varying(25),
    ssdhperawatanpemeriksaangigi_11_51_tv character varying(25),
    ssdhperawatanpemeriksaangigi_21_61_tv character varying(25),
    ssdhperawatanpemeriksaangigi_22_62_tv character varying(25),
    ssdhperawatanpemeriksaangigi_23_63_tv character varying(25),
    ssdhperawatanpemeriksaangigi_24_64_tv character varying(25),
    ssdhperawatanpemeriksaangigi_25_65_tv character varying(25),
    ssdhperawatanpemeriksaangigi_26_tv character varying(25),
    ssdhperawatanpemeriksaangigi_27_tv character varying(25),
    ssdhperawatanpemeriksaangigi_28_tv character varying(25),
    ssdhperawatanpemeriksaangigi_18_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_17_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_16_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_15_55_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_14_54_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_13_53_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_12_52_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_11_51_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_21_61_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_22_62_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_23_63_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_24_64_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_25_65_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_26_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_27_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_28_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_18_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_17_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_16_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_15_55_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_14_54_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_13_53_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_12_52_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_11_51_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_21_61_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_22_62_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_23_63_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_24_64_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_25_65_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_26_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_27_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_28_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_41_81_tv character varying(25),
    ssdhperawatanpemeriksaangigi_42_82_tv character varying(25),
    ssdhperawatanpemeriksaangigi_43_83_tv character varying(25),
    ssdhperawatanpemeriksaangigi_44_84_tv character varying(25),
    ssdhperawatanpemeriksaangigi_45_85_tv character varying(25),
    ssdhperawatanpemeriksaangigi_46_tv character varying(25),
    ssdhperawatanpemeriksaangigi_47_tv character varying(25),
    ssdhperawatanpemeriksaangigi_48_tv character varying(25),
    ssdhperawatanpemeriksaangigi_38_tv character varying(25),
    ssdhperawatanpemeriksaangigi_37_tv character varying(25),
    ssdhperawatanpemeriksaangigi_36_tv character varying(25),
    ssdhperawatanpemeriksaangigi_35_75_tv character varying(25),
    ssdhperawatanpemeriksaangigi_34_74_tv character varying(25),
    ssdhperawatanpemeriksaangigi_33_73_tv character varying(25),
    ssdhperawatanpemeriksaangigi_32_72_tv character varying(25),
    ssdhperawatanpemeriksaangigi_31_71_tv character varying(25),
    ssdhperawatanpemeriksaangigi_41_81_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_42_82_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_43_83_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_44_84_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_45_85_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_46_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_47_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_48_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_38_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_37_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_36_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_35_75_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_34_74_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_33_73_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_32_72_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_31_71_diagnosis character varying(25),
    ssdhperawatanpemeriksaangigi_41_81_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_42_82_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_43_83_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_44_84_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_45_85_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_46_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_47_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_48_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_38_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_37_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_36_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_35_75_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_34_74_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_33_73_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_32_72_rencanaperawatan character varying(25),
    ssdhperawatanpemeriksaangigi_31_71_rencanaperawatan character varying(25),
    sblmperawatanfaktorrisikokaries_sikap character varying(25),
    sblmperawatanfaktorrisikokaries_status character varying(25),
    sblmperawatanfaktorrisikokaries_saliva_tanpastimulasi_hidrasi character varying(25),
    sblmperawatanfaktorrisikokaries_saliva_tanpastimulasi_viskosita character varying(25),
    "sblmperawatanfaktorrisikokaries_saliva_tanpastimulasi_pH" character varying(25),
    sblmperawatanfaktorrisikokaries_saliva_denganstimulasi_hidrasi character varying(25),
    sblmperawatanfaktorrisikokaries_saliva_denganstimulasi_kecepata character varying(25),
    sblmperawatanfaktorrisikokaries_saliva_denganstimulasi_kapasita character varying(25),
    "sblmperawatanfaktorrisikokaries_saliva_denganstimulasi_pH" character varying(25),
    "sblmperawatanfaktorrisikokaries_plak_pH" character varying(25),
    sblmperawatanfaktorrisikokaries_plak_aktivitas character varying(25),
    sblmperawatanfaktorrisikokaries_fluor_pastagigi character varying(25),
    sblmperawatanfaktorrisikokaries_diet_gula character varying(25),
    sblmperawatanfaktorrisikokaries_faktormodifikasi_obatpeningkata character varying(25),
    sblmperawatanfaktorrisikokaries_faktormodifikasi_penyakitpenyeb character varying(25),
    sblmperawatanfaktorrisikokaries_faktormodifikasi_protesa character varying(25),
    sblmperawatanfaktorrisikokaries_faktormodifikasi_kariesaktif character varying(25),
    sblmperawatanfaktorrisikokaries_faktormodifikasi_sikap character varying(25),
    sblmperawatanfaktorrisikokaries_faktormodifikasi_keterangan character varying(25),
    sblmperawatanfaktorrisikokaries_penilaianakhir_saliva character varying(25),
    sblmperawatanfaktorrisikokaries_penilaianakhir_plak character varying(25),
    sblmperawatanfaktorrisikokaries_penilaianakhir_diet character varying(25),
    sblmperawatanfaktorrisikokaries_penilaianakhir_fluor character varying(25),
    sblmperawatanfaktorrisikokaries_penilaianakhir_faktormodifikasi character varying(25),
    ssdhperawatanfaktorrisikokaries_sikap character varying(25),
    ssdhperawatanfaktorrisikokaries_status character varying(25),
    ssdhperawatanfaktorrisikokaries_saliva_tanpastimulasi_hidrasi character varying(25),
    ssdhperawatanfaktorrisikokaries_saliva_tanpastimulasi_viskosita character varying(25),
    "ssdhperawatanfaktorrisikokaries_saliva_tanpastimulasi_pH" character varying(25),
    ssdhperawatanfaktorrisikokaries_saliva_denganstimulasi_hidrasi character varying(25),
    ssdhperawatanfaktorrisikokaries_saliva_denganstimulasi_kecepata character varying(25),
    ssdhperawatanfaktorrisikokaries_saliva_denganstimulasi_kapasita character varying(25),
    "ssdhperawatanfaktorrisikokaries_saliva_denganstimulasi_pH" character varying(25),
    "ssdhperawatanfaktorrisikokaries_plak_pH" character varying(25),
    ssdhperawatanfaktorrisikokaries_plak_aktivitas character varying(25),
    ssdhperawatanfaktorrisikokaries_fluor_pastagigi character varying(25),
    ssdhperawatanfaktorrisikokaries_diet_gula character varying(25),
    ssdhperawatanfaktorrisikokaries_faktormodifikasi_obatpeningkata character varying(25),
    ssdhperawatanfaktorrisikokaries_faktormodifikasi_penyakitpenyeb character varying(25),
    ssdhperawatanfaktorrisikokaries_faktormodifikasi_protesa character varying(25),
    ssdhperawatanfaktorrisikokaries_faktormodifikasi_kariesaktif character varying(25),
    ssdhperawatanfaktorrisikokaries_faktormodifikasi_sikap character varying(25),
    ssdhperawatanfaktorrisikokaries_faktormodifikasi_keterangan character varying(25),
    ssdhperawatanfaktorrisikokaries_penilaianakhir_saliva character varying(25),
    ssdhperawatanfaktorrisikokaries_penilaianakhir_plak character varying(25),
    ssdhperawatanfaktorrisikokaries_penilaianakhir_diet character varying(25),
    ssdhperawatanfaktorrisikokaries_penilaianakhir_fluor character varying(25),
    ssdhperawatanfaktorrisikokaries_penilaianakhir_faktormodifikasi character varying(25),
    sikatgigi2xsehari character varying(255),
    sikatgigi3xsehari character varying(255),
    flossingsetiaphari character varying(255),
    sikatinterdental character varying(255),
    agenantibakteri_obatkumur character varying(255),
    guladancemilandiantarawaktumakanutama character varying(255),
    minumanasamtinggi character varying(255),
    minumanberkafein character varying(255),
    meningkatkanasupanair character varying(255),
    obatkumurbakingsoda character varying(255),
    konsumsimakananminumanberbahandasarsusu character varying(255),
    permenkaretxylitolccpacp character varying(255),
    pastagigi character varying(255),
    kumursetiaphari character varying(255),
    kumursetiapminggu character varying(255),
    gelsetiaphari character varying(255),
    gelsetiapminggu character varying(255),
    perlu character varying(255),
    tidakperlu character varying(255),
    evaluasi_sikatgigi2xsehari character varying(255),
    evaluasi_sikatgigi3xsehari character varying(255),
    evaluasi_flossingsetiaphari character varying(255),
    evaluasi_sikatinterdental character varying(255),
    evaluasi_agenantibakteri_obatkumur character varying(255),
    evaluasi_guladancemilandiantarawaktumakanutama character varying(255),
    evaluasi_minumanasamtinggi character varying(255),
    evaluasi_minumanberkafein character varying(255),
    evaluasi_meningkatkanasupanair character varying(255),
    evaluasi_obatkumurbakingsoda character varying(255),
    evaluasi_konsumsimakananminumanberbahandasarsusu character varying(255),
    evaluasi_permenkaretxylitolccpacp character varying(255),
    evaluasi_pastagigi character varying(255),
    evaluasi_kumursetiaphari character varying(255),
    evaluasi_kumursetiapminggu character varying(255),
    evaluasi_gelsetiaphari character varying(255),
    evaluasi_gelsetiapminggu character varying(255),
    evaluasi_perlu character varying(255),
    evaluasi_tidakperlu character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    uploadrestorasibefore text,
    uploadrestorasiafter text,
    sblmperawatanfaktorrisikokaries_fluor_airminum character varying(100),
    sblmperawatanfaktorrisikokaries_fluor_topikal character varying(100),
    sblmperawatanfaktorrisikokaries_diet_asam character varying(100),
    ssdhperawatanfaktorrisikokaries_fluor_airminum character varying(100),
    ssdhperawatanfaktorrisikokaries_fluor_topikal character varying(100),
    ssdhperawatanfaktorrisikokaries_diet_asam character varying(100),
    status_emr character varying(10),
    status_penilaian character varying(10)
);


ALTER TABLE public.emrkonservasis OWNER TO rsyarsi;

--
-- TOC entry 3757 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN emrkonservasis.status_emr; Type: COMMENT; Schema: public; Owner: rsyarsi
--

COMMENT ON COLUMN public.emrkonservasis.status_emr IS '[ OPEN, WRITE, FINISH ]';


--
-- TOC entry 3758 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN emrkonservasis.status_penilaian; Type: COMMENT; Schema: public; Owner: rsyarsi
--

COMMENT ON COLUMN public.emrkonservasis.status_penilaian IS '[ OPEN, WRITE, FINISH ]';


--
-- TOC entry 220 (class 1259 OID 16455)
-- Name: emrortodonsies; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.emrortodonsies (
    id uuid NOT NULL,
    noregister character varying(25),
    noepisode character varying(25),
    operator character varying(225),
    nim character varying(225),
    pembimbing character varying(225),
    tanggal character varying(225),
    namapasien character varying(225),
    suku character varying(225),
    umur character varying(225),
    jeniskelamin character varying(225),
    alamat character varying(225),
    telepon character varying(225),
    pekerjaan character varying(225),
    rujukandari character varying(225),
    namaayah character varying(225),
    sukuayah character varying(225),
    umurayah character varying(225),
    namaibu character varying(225),
    sukuibu character varying(225),
    umuribu character varying(225),
    pekerjaanorangtua character varying(225),
    alamatorangtua character varying(225),
    pendaftaran character varying(225),
    pencetakan character varying(225),
    pemasanganalat character varying(225),
    waktuperawatan_retainer character varying(225),
    keluhanutama text,
    kelainanendoktrin character varying(225),
    penyakitpadamasaanak character varying(225),
    alergi character varying(225),
    kelainansaluranpernapasan character varying(225),
    tindakanoperasi character varying(225),
    gigidesidui character varying(225),
    gigibercampur character varying(225),
    gigipermanen character varying(225),
    durasi character varying(225),
    frekuensi character varying(225),
    intensitas character varying(225),
    kebiasaanjelekketerangan character varying(225),
    riwayatkeluarga character varying(225),
    ayah character varying(225),
    ibu character varying(225),
    saudara character varying(225),
    riwayatkeluargaketerangan character varying(225),
    jasmani character varying(25),
    mental character varying(25),
    tinggibadan character varying(225),
    beratbadan character varying(225),
    indeksmassatubuh character varying(225),
    statusgizi character varying(25),
    kategori character varying(350),
    lebarkepala character varying(225),
    panjangkepala character varying(225),
    indekskepala character varying(225),
    bentukkepala character varying(225),
    panjangmuka character varying(225),
    lebarmuka character varying(225),
    indeksmuka character varying(225),
    bentukmuka character varying(225),
    bentuk character varying(25),
    profilmuka character varying(25),
    senditemporomandibulat_tmj character varying(25),
    tmj_keterangan text,
    bibirposisiistirahat character varying(25),
    tunusototmastikasi character varying(25),
    tunusototmastikasi_keterangan text,
    tunusototbibir character varying(25),
    tunusototbibir_keterangan text,
    freewayspace character varying(225),
    pathofclosure character varying(225),
    higienemulutohi character varying(25),
    polaatrisi character varying(25),
    regio character varying(225),
    lingua character varying(25),
    intraoral_lainlain text,
    palatumvertikal character varying(25),
    palatumlateral character varying(25),
    gingiva character varying(25),
    gingiva_keterangan text,
    mukosa character varying(25),
    mukosa_keterangan text,
    frenlabiisuperior character varying(25),
    frenlabiiinferior character varying(25),
    frenlingualis character varying(25),
    ketr character varying(25),
    tonsila character varying(25),
    fonetik character varying(225),
    image_pemeriksaangigi text,
    tampakdepantakterlihatgigi text,
    fotomuka_bentukmuka text,
    tampaksamping text,
    fotomuka_profilmuka text,
    tampakdepansenyumterlihatgigi text,
    tampakmiring text,
    tampaksampingkanan text,
    tampakdepan text,
    tampaksampingkiri text,
    tampakoklusalatas text,
    tampakoklusalbawah text,
    bentuklengkunggigi_ra character varying(25),
    bentuklengkunggigi_rb character varying(25),
    malposisigigiindividual_rahangatas_kanan1 character varying(225),
    malposisigigiindividual_rahangatas_kanan2 character varying(225),
    malposisigigiindividual_rahangatas_kanan3 character varying(225),
    malposisigigiindividual_rahangatas_kanan4 character varying(225),
    malposisigigiindividual_rahangatas_kanan5 character varying(225),
    malposisigigiindividual_rahangatas_kanan6 character varying(225),
    malposisigigiindividual_rahangatas_kanan7 character varying(225),
    malposisigigiindividual_rahangatas_kiri1 character varying(225),
    malposisigigiindividual_rahangatas_kiri2 character varying(225),
    malposisigigiindividual_rahangatas_kiri3 character varying(225),
    malposisigigiindividual_rahangatas_kiri4 character varying(225),
    malposisigigiindividual_rahangatas_kiri5 character varying(225),
    malposisigigiindividual_rahangatas_kiri6 character varying(225),
    malposisigigiindividual_rahangatas_kiri7 character varying(225),
    malposisigigiindividual_rahangbawah_kanan1 character varying(225),
    malposisigigiindividual_rahangbawah_kanan2 character varying(225),
    malposisigigiindividual_rahangbawah_kanan3 character varying(225),
    malposisigigiindividual_rahangbawah_kanan4 character varying(225),
    malposisigigiindividual_rahangbawah_kanan5 character varying(225),
    malposisigigiindividual_rahangbawah_kanan6 character varying(225),
    malposisigigiindividual_rahangbawah_kanan7 character varying(225),
    malposisigigiindividual_rahangbawah_kiri1 character varying(225),
    malposisigigiindividual_rahangbawah_kiri2 character varying(225),
    malposisigigiindividual_rahangbawah_kiri3 character varying(225),
    malposisigigiindividual_rahangbawah_kiri4 character varying(225),
    malposisigigiindividual_rahangbawah_kiri5 character varying(225),
    malposisigigiindividual_rahangbawah_kiri6 character varying(225),
    malposisigigiindividual_rahangbawah_kiri7 character varying(225),
    overjet character varying(225),
    overbite character varying(225),
    palatalbite character varying(10),
    deepbite character varying(10),
    anterior_openbite character varying(10),
    edgetobite character varying(10),
    anterior_crossbite character varying(10),
    posterior_openbite character varying(10),
    scissorbite character varying(10),
    cusptocuspbite character varying(10),
    relasimolarpertamakanan character varying(10),
    relasimolarpertamakiri character varying(10),
    relasikaninuskanan character varying(10),
    relasikaninuskiri character varying(10),
    garistengahrahangbawahterhadaprahangatas character varying(225),
    garisinterinsisivisentralterhadapgaristengahrahangra character varying(225),
    garisinterinsisivisentralterhadapgaristengahrahangra_mm character varying(225),
    garisinterinsisivisentralterhadapgaristengahrahangrb character varying(225),
    garisinterinsisivisentralterhadapgaristengahrahangrb_mm character varying(225),
    lebarmesiodistalgigi_rahangatas_kanan1 character varying(225),
    lebarmesiodistalgigi_rahangatas_kanan2 character varying(225),
    lebarmesiodistalgigi_rahangatas_kanan3 character varying(225),
    lebarmesiodistalgigi_rahangatas_kanan4 character varying(225),
    lebarmesiodistalgigi_rahangatas_kanan5 character varying(225),
    lebarmesiodistalgigi_rahangatas_kanan6 character varying(225),
    lebarmesiodistalgigi_rahangatas_kanan7 character varying(225),
    lebarmesiodistalgigi_rahangatas_kiri1 character varying(225),
    lebarmesiodistalgigi_rahangatas_kiri2 character varying(225),
    lebarmesiodistalgigi_rahangatas_kiri3 character varying(225),
    lebarmesiodistalgigi_rahangatas_kiri4 character varying(225),
    lebarmesiodistalgigi_rahangatas_kiri5 character varying(225),
    lebarmesiodistalgigi_rahangatas_kiri6 character varying(225),
    lebarmesiodistalgigi_rahangatas_kiri7 character varying(225),
    lebarmesiodistalgigi_rahangbawah_kanan1 character varying(225),
    lebarmesiodistalgigi_rahangbawah_kanan2 character varying(225),
    lebarmesiodistalgigi_rahangbawah_kanan3 character varying(225),
    lebarmesiodistalgigi_rahangbawah_kanan4 character varying(225),
    lebarmesiodistalgigi_rahangbawah_kanan5 character varying(225),
    lebarmesiodistalgigi_rahangbawah_kanan6 character varying(225),
    lebarmesiodistalgigi_rahangbawah_kanan7 character varying(225),
    lebarmesiodistalgigi_rahangbawah_kiri1 character varying(225),
    lebarmesiodistalgigi_rahangbawah_kiri2 character varying(225),
    lebarmesiodistalgigi_rahangbawah_kiri3 character varying(225),
    lebarmesiodistalgigi_rahangbawah_kiri4 character varying(225),
    lebarmesiodistalgigi_rahangbawah_kiri5 character varying(225),
    lebarmesiodistalgigi_rahangbawah_kiri6 character varying(225),
    lebarmesiodistalgigi_rahangbawah_kiri7 character varying(225),
    skemafotooklusalgigidarimodelstudi character varying(225),
    jumlahmesiodistal character varying(225),
    jarakp1p2pengukuran character varying(225),
    jarakp1p2perhitungan character varying(225),
    diskrepansip1p2_mm character varying(225),
    diskrepansip1p2 character varying(25),
    jarakm1m1pengukuran character varying(225),
    jarakm1m1perhitungan character varying(225),
    diskrepansim1m2_mm character varying(225),
    diskrepansim1m2 character varying(225),
    diskrepansi_keterangan character varying(225),
    jumlahlebarmesiodistalgigidarim1m1 character varying(225),
    jarakp1p1tonjol character varying(225),
    indeksp character varying(225),
    lengkunggigiuntukmenampunggigigigi character varying(25),
    jarakinterfossacaninus character varying(225),
    indeksfc character varying(225),
    lengkungbasaluntukmenampunggigigigi character varying(25),
    inklinasigigigigiregioposterior character varying(25),
    metodehowes_keterangan text,
    aldmetode text,
    overjetawal character varying(225),
    overjetakhir character varying(225),
    rahangatasdiskrepansi character varying(225),
    rahangbawahdiskrepansi character varying(225),
    fotosefalometri text,
    fotopanoramik text,
    maloklusiangleklas character varying(225),
    hubunganskeletal character varying(225),
    malrelasi character varying(225),
    malposisi character varying(225),
    estetik boolean,
    dental boolean,
    skeletal boolean,
    fungsipenguyahanal boolean,
    crowding boolean,
    spacing boolean,
    protrusif boolean,
    retrusif boolean,
    malposisiindividual boolean,
    maloklusi_crossbite boolean,
    maloklusi_lainlain boolean,
    maloklusi_lainlainketerangan text,
    rapencabutan boolean,
    raekspansi boolean,
    ragrinding boolean,
    raplataktif boolean,
    rbpencabutan boolean,
    rbekspansi boolean,
    rbgrinding boolean,
    rbplataktif boolean,
    analisisetiologimaloklusi character varying(225),
    pasiendirujukkebagian character varying(225),
    pencarianruanguntuk character varying(225),
    koreksimalposisigigiindividual character varying(225),
    retensi character varying(225),
    pencarianruang character varying(225),
    koreksimalposisigigiindividual_rahangatas character varying(225),
    koreksimalposisigigiindividual_rahangbawah character varying(225),
    intruksipadapasien character varying(225),
    retainer character varying(225),
    gambarplataktif_rahangatas text,
    gambarplataktif_rahangbawah text,
    keterangangambar character varying(225),
    prognosis character varying(25),
    prognosis_a character varying(25),
    prognosis_b character varying(25),
    prognosis_c character varying(25),
    indikasiperawatan character varying(25),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    status_emr character varying(10),
    status_penilaian character varying(10)
);


ALTER TABLE public.emrortodonsies OWNER TO rsyarsi;

--
-- TOC entry 3759 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN emrortodonsies.status_emr; Type: COMMENT; Schema: public; Owner: rsyarsi
--

COMMENT ON COLUMN public.emrortodonsies.status_emr IS '[ OPEN, WRITE, FINISH ]';


--
-- TOC entry 3760 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN emrortodonsies.status_penilaian; Type: COMMENT; Schema: public; Owner: rsyarsi
--

COMMENT ON COLUMN public.emrortodonsies.status_penilaian IS '[ OPEN, WRITE, FINISH ]';


--
-- TOC entry 221 (class 1259 OID 16460)
-- Name: emrpedodontie_behaviorratings; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.emrpedodontie_behaviorratings (
    id uuid NOT NULL,
    emrid uuid NOT NULL,
    frankscale text NOT NULL,
    beforetreatment text NOT NULL,
    duringtreatment text NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    userentryname character varying(250)
);


ALTER TABLE public.emrpedodontie_behaviorratings OWNER TO rsyarsi;

--
-- TOC entry 222 (class 1259 OID 16465)
-- Name: emrpedodontie_treatmenplans; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.emrpedodontie_treatmenplans (
    id uuid NOT NULL,
    emrid uuid,
    oralfinding text,
    diagnosis text,
    treatmentplanning text,
    userentryname character varying(250),
    updated_at timestamp without time zone,
    created_at timestamp without time zone,
    userentry uuid,
    datetreatmentplanentry timestamp without time zone
);


ALTER TABLE public.emrpedodontie_treatmenplans OWNER TO rsyarsi;

--
-- TOC entry 223 (class 1259 OID 16470)
-- Name: emrpedodontie_treatmens; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.emrpedodontie_treatmens (
    id uuid NOT NULL,
    emrid uuid,
    datetreatment timestamp without time zone,
    itemtreatment text,
    userentryname character varying(250),
    updated_at timestamp without time zone,
    created_at timestamp without time zone,
    supervisorname character varying(250),
    supervisorvalidate timestamp without time zone,
    userentry uuid,
    supervisousername uuid
);


ALTER TABLE public.emrpedodontie_treatmens OWNER TO rsyarsi;

--
-- TOC entry 224 (class 1259 OID 16475)
-- Name: emrpedodonties; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.emrpedodonties (
    id uuid NOT NULL,
    tanggalmasuk character varying(225),
    nim character varying(225),
    namamahasiswa character varying(225),
    tahunklinik character varying(225),
    namasupervisor character varying(225),
    tandatangan character varying(225),
    namapasien character varying(225),
    jeniskelamin character varying(225),
    alamatpasien character varying(225),
    usiapasien character varying(225),
    pendidikan character varying(225),
    tgllahirpasien character varying(225),
    namaorangtua character varying(225),
    telephone character varying(225),
    pekerjaan character varying(225),
    dokteranak character varying(225),
    alamatpekerjaan character varying(225),
    telephonedranak character varying(225),
    anamnesis character varying(225),
    noregister character varying(25),
    noepisode character varying(25),
    physicalgrowth character varying(3),
    heartdesease character varying(3),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    bruiseeasily character varying(3),
    anemia character varying(3),
    hepatitis character varying(3),
    allergic character varying(3),
    takinganymedicine character varying(3),
    takinganymedicineobat character varying(225),
    beenhospitalized character varying(3),
    beenhospitalizedalasan character varying(225),
    toothache character varying(3),
    childtoothache character varying(3),
    firstdental character varying(3),
    unfavorabledentalexperience character varying(3),
    "where" text,
    reason text,
    fingersucking character varying(150),
    diffycultyopeningsjaw character varying(3),
    howoftenbrushtooth text,
    howoftenbrushtoothkali character varying(150),
    usefluoridepasta character varying(3),
    fluoridetreatmen character varying(3),
    ifyes text,
    bilateralsymmetry text,
    asymmetry text,
    straight text,
    convex text,
    concave text,
    lipsseal character varying(10),
    clicking character varying(3),
    clickingleft character varying(10),
    clickingright character varying(10),
    pain character varying(3),
    painleft character varying(10),
    painright character varying(10),
    bodypostur character varying(50),
    gingivitis text,
    stomatitis text,
    dentalanomali character varying(3),
    prematurloss text,
    overretainedprimarytooth text,
    odontogramfoto character varying(225),
    gumboil text,
    stageofdentition character varying(50),
    franklscale_definitelynegative_before_treatment character varying(50),
    franklscale_definitelynegative_during_treatment character varying(50),
    franklscale_negative_before_treatment character varying(50),
    franklscale_negative_during_treatment character varying(50),
    franklscale_positive_before_treatment character varying(50),
    franklscale_positive_during_treatment character varying(50),
    franklscale_definitelypositive_before_treatment character varying(50),
    franklscale_definitelypositive_during_treatment character varying(50),
    buccal_18 character varying(50),
    buccal_17 character varying(50),
    buccal_16 character varying(50),
    buccal_15 character varying(50),
    buccal_14 character varying(50),
    buccal_13 character varying(50),
    buccal_12 character varying(50),
    buccal_11 character varying(50),
    buccal_21 character varying(50),
    buccal_22 character varying(50),
    buccal_23 character varying(50),
    buccal_24 character varying(50),
    buccal_25 character varying(50),
    buccal_26 character varying(50),
    buccal_27 character varying(50),
    buccal_28 character varying(50),
    palatal_55 character varying(50),
    palatal_54 character varying(50),
    palatal_53 character varying(50),
    palatal_52 character varying(50),
    palatal_51 character varying(50),
    palatal_61 character varying(50),
    palatal_62 character varying(50),
    palatal_63 character varying(50),
    palatal_64 character varying(50),
    palatal_65 character varying(50),
    buccal_85 character varying(50),
    buccal_84 character varying(50),
    buccal_83 character varying(50),
    buccal_82 character varying(50),
    buccal_81 character varying(50),
    buccal_71 character varying(50),
    buccal_72 character varying(50),
    buccal_73 character varying(50),
    buccal_74 character varying(50),
    buccal_75 character varying(50),
    palatal_48 character varying(50),
    palatal_47 character varying(50),
    palatal_46 character varying(50),
    palatal_45 character varying(50),
    palatal_44 character varying(50),
    palatal_43 character varying(50),
    palatal_42 character varying(50),
    palatal_41 character varying(50),
    palatal_31 character varying(50),
    palatal_32 character varying(50),
    palatal_33 character varying(50),
    palatal_34 character varying(50),
    palatal_35 character varying(50),
    palatal_36 character varying(50),
    palatal_37 character varying(50),
    palatal_38 character varying(50),
    dpalatal character varying(50),
    epalatal character varying(50),
    fpalatal character varying(50),
    defpalatal character varying(50),
    dlingual character varying(50),
    elingual character varying(50),
    flingual character varying(50),
    deflingual character varying(50),
    status_emr character varying(10),
    status_penilaian character varying(10)
);


ALTER TABLE public.emrpedodonties OWNER TO rsyarsi;

--
-- TOC entry 3761 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN emrpedodonties.status_emr; Type: COMMENT; Schema: public; Owner: rsyarsi
--

COMMENT ON COLUMN public.emrpedodonties.status_emr IS '[ OPEN, WRITE, FINISH ]';


--
-- TOC entry 3762 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN emrpedodonties.status_penilaian; Type: COMMENT; Schema: public; Owner: rsyarsi
--

COMMENT ON COLUMN public.emrpedodonties.status_penilaian IS '[ OPEN, WRITE, FINISH ]';


--
-- TOC entry 225 (class 1259 OID 16480)
-- Name: emrperiodontie_soaps; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.emrperiodontie_soaps (
    id uuid NOT NULL,
    datesoap timestamp without time zone,
    terapi_s text,
    terapi_o text,
    terapi_a text,
    terapi_p text,
    user_entry character varying(150),
    user_entry_name character varying(255),
    user_verify character varying(150),
    user_verify_name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    idemr uuid,
    active integer DEFAULT 1,
    date_verify timestamp without time zone
);


ALTER TABLE public.emrperiodontie_soaps OWNER TO rsyarsi;

--
-- TOC entry 226 (class 1259 OID 16486)
-- Name: emrperiodonties; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.emrperiodonties (
    id uuid NOT NULL,
    nama_mahasiswa character varying(225),
    npm character varying(25),
    tahun_klinik timestamp(6) without time zone,
    opsi_imagemahasiswa character varying(225),
    noregister character varying(25),
    noepisode character varying(25),
    no_rekammedik character varying(10),
    kasus_pasien text,
    tanggal_pemeriksaan timestamp(6) without time zone,
    pendidikan_pasien character varying(225),
    nama_pasien character varying(225),
    umur_pasien character varying(25),
    jenis_kelamin_pasien character varying(25),
    alamat character varying(350),
    no_telephone_pasien character varying(65),
    pemeriksa text,
    operator1 character varying(225),
    operator2 character varying(225),
    operator3 character varying(225),
    operator4 character varying(225),
    konsuldari character varying(225),
    keluhanutama text,
    anamnesis text,
    gusi_mudah_berdarah character varying(25),
    gusi_mudah_berdarah_lainlain character varying(25),
    penyakit_sistemik character varying(25),
    penyakit_sistemik_bilaada character varying(25),
    penyakit_sistemik_obat character varying(25),
    diabetes_melitus character varying(25),
    diabetes_melituskadargula character varying(25),
    merokok character varying(1225),
    merokok_perhari character varying(125),
    merokok_tahun_awal timestamp(6) without time zone,
    merokok_tahun_akhir timestamp(6) without time zone,
    gigi_pernah_tanggal_dalam_keadaan_baik character varying(25),
    keadaan_umum character varying(25),
    tekanan_darah character varying(25),
    extra_oral character varying(25),
    intra_oral character varying(25),
    oral_hygiene_bop character varying(25),
    oral_hygiene_ci character varying(25),
    oral_hygiene_pi character varying(25),
    oral_hygiene_ohis character varying(25),
    kesimpulan_ohis character varying(25),
    rakn_keaadan_gingiva character varying(25),
    rakn_karang_gigi character varying(25),
    rakn_oklusi character varying(25),
    rakn_artikulasi character varying(25),
    rakn_abrasi_atrisi_abfraksi character varying(25),
    ram_keaadan_gingiva character varying(25),
    ram_karang_gigi character varying(25),
    ram_oklusi character varying(25),
    ram_artikulasi character varying(25),
    ram_abrasi_atrisi_abfraksi character varying(25),
    rakr_keaadan_gingiva character varying(25),
    rakr_karang_gigi character varying(25),
    rakr_oklusi character varying(25),
    rakr_artikulasi character varying(25),
    rakr_abrasi_atrisi_abfraksi character varying(25),
    rbkn_keaadan_gingiva character varying(25),
    rbkn_karang_gigi character varying(25),
    rbkn_oklusi character varying(25),
    rbkn_artikulasi character varying(25),
    rbkn_abrasi_atrisi_abfraksi character varying(25),
    rbm_keaadan_gingiva character varying(25),
    rbm_karang_gigi character varying(25),
    rbm_oklusi character varying(25),
    rbm_artikulasi character varying(25),
    rbm_abrasi_atrisi_abfraksi character varying(25),
    rbkr_keaadan_gingiva character varying(25),
    rbkr_karang_gigi character varying(25),
    rbkr_oklusi character varying(25),
    rbkr_artikulasi character varying(25),
    rbkr_abrasi_atrisi_abfraksi character varying(25),
    rakn_1_v text,
    rakn_1_g text,
    rakn_1_pm text,
    rakn_1_pb text,
    rakn_1_pd text,
    rakn_1_pp character varying(25),
    rakn_1_o text,
    rakn_1_r text,
    rakn_1_la text,
    rakn_1_mp text,
    rakn_1_bop text,
    rakn_1_tk character varying(25),
    rakn_1_fi character varying(25),
    rakn_1_k character varying(25),
    rakn_1_t character varying(25),
    rakn_2_v character varying(25),
    rakn_2_g character varying(25),
    rakn_2_pm character varying(25),
    rakn_2_pb character varying(25),
    rakn_2_pd character varying(25),
    rakn_2_pp character varying(25),
    rakn_2_o character varying(25),
    rakn_2_r character varying(25),
    rakn_2_la character varying(25),
    rakn_2_mp character varying(25),
    rakn_2_bop character varying(25),
    rakn_2_tk character varying(25),
    rakn_2_fi character varying(25),
    rakn_2_k character varying(25),
    rakn_2_t character varying(25),
    rakn_3_v character varying(25),
    rakn_3_g character varying(25),
    rakn_3_pm character varying(25),
    rakn_3_pb character varying(25),
    rakn_3_pd character varying(25),
    rakn_3_pp character varying(25),
    rakn_3_o character varying(25),
    rakn_3_r character varying(25),
    rakn_3_la character varying(25),
    rakn_3_mp character varying(25),
    rakn_3_bop character varying(25),
    rakn_3_tk character varying(25),
    rakn_3_fi character varying(25),
    rakn_3_k character varying(25),
    rakn_3_t character varying(25),
    rakn_4_v character varying(25),
    rakn_4_g character varying(25),
    rakn_4_pm character varying(25),
    rakn_4_pb character varying(25),
    rakn_4_pd character varying(25),
    rakn_4_pp character varying(25),
    rakn_4_o character varying(25),
    rakn_4_r character varying(25),
    rakn_4_la character varying(25),
    rakn_4_mp character varying(25),
    rakn_4_bop character varying(25),
    rakn_4_tk character varying(25),
    rakn_4_fi character varying(25),
    rakn_4_k character varying(25),
    rakn_4_t character varying(25),
    rakn_5_v character varying(25),
    rakn_5_g character varying(25),
    rakn_5_pm character varying(25),
    rakn_5_pb character varying(25),
    rakn_5_pd character varying(25),
    rakn_5_pp character varying(25),
    rakn_5_o character varying(25),
    rakn_5_r character varying(25),
    rakn_5_la character varying(25),
    rakn_5_mp character varying(25),
    rakn_5_bop character varying(25),
    rakn_5_tk character varying(25),
    rakn_5_fi character varying(25),
    rakn_5_k character varying(25),
    rakn_5_t character varying(25),
    rakn_6_v character varying(25),
    rakn_6_g character varying(25),
    rakn_6_pm character varying(25),
    rakn_6_pb character varying(25),
    rakn_6_pd character varying(25),
    rakn_6_pp character varying(25),
    rakn_6_o character varying(25),
    rakn_6_r character varying(25),
    rakn_6_la character varying(25),
    rakn_6_mp character varying(25),
    rakn_6_bop character varying(25),
    rakn_6_tk character varying(25),
    rakn_6_fi character varying(25),
    rakn_6_k character varying(25),
    rakn_6_t character varying(25),
    rakn_7_v character varying(25),
    rakn_7_g character varying(25),
    rakn_7_pm character varying(25),
    rakn_7_pb character varying(25),
    rakn_7_pd character varying(25),
    rakn_7_pp character varying(25),
    rakn_7_o character varying(25),
    rakn_7_r character varying(25),
    rakn_7_la character varying(25),
    rakn_7_mp character varying(25),
    rakn_7_bop character varying(25),
    rakn_7_tk character varying(25),
    rakn_7_fi character varying(25),
    rakn_7_k character varying(25),
    rakn_7_t character varying(25),
    rakn_8_v character varying(25),
    rakn_8_g character varying(25),
    rakn_8_pm character varying(25),
    rakn_8_pb character varying(25),
    rakn_8_pd character varying(25),
    rakn_8_pp character varying(25),
    rakn_8_o character varying(25),
    rakn_8_r character varying(25),
    rakn_8_la character varying(25),
    rakn_8_mp character varying(25),
    rakn_8_bop character varying(25),
    rakn_8_tk character varying(25),
    rakn_8_fi character varying(25),
    rakn_8_k character varying(25),
    rakn_8_t character varying(25),
    rakr_1_v character varying(25),
    rakr_1_g character varying(25),
    rakr_1_pm character varying(25),
    rakr_1_pb character varying(25),
    rakr_1_pd character varying(25),
    rakr_1_pp character varying(25),
    rakr_1_o character varying(25),
    rakr_1_r character varying(25),
    rakr_1_la character varying(25),
    rakr_1_mp character varying(25),
    rakr_1_bop character varying(25),
    rakr_1_tk character varying(25),
    rakr_1_fi character varying(25),
    rakr_1_k character varying(25),
    rakr_1_t character varying(25),
    rakr_2_v character varying(25),
    rakr_2_g character varying(25),
    rakr_2_pm character varying(25),
    rakr_2_pb character varying(25),
    rakr_2_pd character varying(25),
    rakr_2_pp character varying(25),
    rakr_2_o character varying(25),
    rakr_2_r character varying(25),
    rakr_2_la character varying(25),
    rakr_2_mp character varying(25),
    rakr_2_bop character varying(25),
    rakr_2_tk character varying(25),
    rakr_2_fi character varying(25),
    rakr_2_k character varying(25),
    rakr_2_t character varying(25),
    rakr_3_v character varying(25),
    rakr_3_g character varying(25),
    rakr_3_pm character varying(25),
    rakr_3_pb character varying(25),
    rakr_3_pd character varying(25),
    rakr_3_pp character varying(25),
    rakr_3_o character varying(25),
    rakr_3_r character varying(25),
    rakr_3_la character varying(25),
    rakr_3_mp character varying(25),
    rakr_3_bop character varying(25),
    rakr_3_tk character varying(25),
    rakr_3_fi character varying(25),
    rakr_3_k character varying(25),
    rakr_3_t character varying(25),
    rakr_4_v character varying(25),
    rakr_4_g character varying(25),
    rakr_4_pm character varying(25),
    rakr_4_pb character varying(25),
    rakr_4_pd character varying(25),
    rakr_4_pp character varying(25),
    rakr_4_o character varying(25),
    rakr_4_r character varying(25),
    rakr_4_la character varying(25),
    rakr_4_mp character varying(25),
    rakr_4_bop character varying(25),
    rakr_4_tk character varying(25),
    rakr_4_fi character varying(25),
    rakr_4_k character varying(25),
    rakr_4_t character varying(25),
    rakr_5_v character varying(25),
    rakr_5_g character varying(25),
    rakr_5_pm character varying(25),
    rakr_5_pb character varying(25),
    rakr_5_pd character varying(25),
    rakr_5_pp character varying(25),
    rakr_5_o character varying(25),
    rakr_5_r character varying(25),
    rakr_5_la character varying(25),
    rakr_5_mp character varying(25),
    rakr_5_bop character varying(25),
    rakr_5_tk character varying(25),
    rakr_5_fi character varying(25),
    rakr_5_k character varying(25),
    rakr_5_t character varying(25),
    rakr_6_v character varying(25),
    rakr_6_g character varying(25),
    rakr_6_pm character varying(25),
    rakr_6_pb character varying(25),
    rakr_6_pd character varying(25),
    rakr_6_pp character varying(25),
    rakr_6_o character varying(25),
    rakr_6_r character varying(25),
    rakr_6_la character varying(25),
    rakr_6_mp character varying(25),
    rakr_6_bop character varying(25),
    rakr_6_tk character varying(25),
    rakr_6_fi character varying(25),
    rakr_6_k character varying(25),
    rakr_6_t character varying(25),
    rakr_7_v character varying(25),
    rakr_7_g character varying(25),
    rakr_7_pm character varying(25),
    rakr_7_pb character varying(25),
    rakr_7_pd character varying(25),
    rakr_7_pp character varying(25),
    rakr_7_o character varying(25),
    rakr_7_r character varying(25),
    rakr_7_la character varying(25),
    rakr_7_mp character varying(25),
    rakr_7_bop character varying(25),
    rakr_7_tk character varying(25),
    rakr_7_fi character varying(25),
    rakr_7_k character varying(25),
    rakr_7_t character varying(25),
    rakr_8_v character varying(25),
    rakr_8_g character varying(25),
    rakr_8_pm character varying(25),
    rakr_8_pb character varying(25),
    rakr_8_pd character varying(25),
    rakr_8_pp character varying(25),
    rakr_8_o character varying(25),
    rakr_8_r character varying(25),
    rakr_8_la character varying(25),
    rakr_8_mp character varying(25),
    rakr_8_bop character varying(25),
    rakr_8_tk character varying(25),
    rakr_8_fi character varying(25),
    rakr_8_k character varying(25),
    rakr_8_t character varying(25),
    rbkn_1_v character varying(25),
    rbkn_1_g character varying(25),
    rbkn_1_pm character varying(25),
    rbkn_1_pb character varying(25),
    rbkn_1_pd character varying(25),
    rbkn_1_pp character varying(25),
    rbkn_1_o character varying(25),
    rbkn_1_r character varying(25),
    rbkn_1_la character varying(25),
    rbkn_1_mp character varying(25),
    rbkn_1_bop character varying(25),
    rbkn_1_tk character varying(25),
    rbkn_1_fi character varying(25),
    rbkn_1_k character varying(25),
    rbkn_1_t character varying(25),
    rbkn_2_v character varying(25),
    rbkn_2_g character varying(25),
    rbkn_2_pm character varying(25),
    rbkn_2_pb character varying(25),
    rbkn_2_pd character varying(25),
    rbkn_2_pp character varying(25),
    rbkn_2_o character varying(25),
    rbkn_2_r character varying(25),
    rbkn_2_la character varying(25),
    rbkn_2_mp character varying(25),
    rbkn_2_bop character varying(25),
    rbkn_2_tk character varying(25),
    rbkn_2_fi character varying(25),
    rbkn_2_k character varying(25),
    rbkn_2_t character varying(25),
    rbkn_3_v character varying(25),
    rbkn_3_g character varying(25),
    rbkn_3_pm character varying(25),
    rbkn_3_pb character varying(25),
    rbkn_3_pd character varying(25),
    rbkn_3_pp character varying(25),
    rbkn_3_o character varying(25),
    rbkn_3_r character varying(25),
    rbkn_3_la character varying(25),
    rbkn_3_mp character varying(25),
    rbkn_3_bop character varying(25),
    rbkn_3_tk character varying(25),
    rbkn_3_fi character varying(25),
    rbkn_3_k character varying(25),
    rbkn_3_t character varying(25),
    rbkn_4_v character varying(25),
    rbkn_4_g character varying(25),
    rbkn_4_pm character varying(25),
    rbkn_4_pb character varying(25),
    rbkn_4_pd character varying(25),
    rbkn_4_pp character varying(25),
    rbkn_4_o character varying(25),
    rbkn_4_r character varying(25),
    rbkn_4_la character varying(25),
    rbkn_4_mp character varying(25),
    rbkn_4_bop character varying(25),
    rbkn_4_tk character varying(25),
    rbkn_4_fi character varying(25),
    rbkn_4_k character varying(25),
    rbkn_4_t character varying(25),
    rbkn_5_v character varying(25),
    rbkn_5_g character varying(25),
    rbkn_5_pm character varying(25),
    rbkn_5_pb character varying(25),
    rbkn_5_pd character varying(25),
    rbkn_5_pp character varying(25),
    rbkn_5_o character varying(25),
    rbkn_5_r character varying(25),
    rbkn_5_la character varying(25),
    rbkn_5_mp character varying(25),
    rbkn_5_bop character varying(25),
    rbkn_5_tk character varying(25),
    rbkn_5_fi character varying(25),
    rbkn_5_k character varying(25),
    rbkn_5_t character varying(25),
    rbkn_6_v character varying(25),
    rbkn_6_g character varying(25),
    rbkn_6_pm character varying(25),
    rbkn_6_pb character varying(25),
    rbkn_6_pd character varying(25),
    rbkn_6_pp character varying(25),
    rbkn_6_o character varying(25),
    rbkn_6_r character varying(25),
    rbkn_6_la character varying(25),
    rbkn_6_mp character varying(25),
    rbkn_6_bop character varying(25),
    rbkn_6_tk character varying(25),
    rbkn_6_fi character varying(25),
    rbkn_6_k character varying(25),
    rbkn_6_t character varying(25),
    rbkn_7_v character varying(25),
    rbkn_7_g character varying(25),
    rbkn_7_pm character varying(25),
    rbkn_7_pb character varying(25),
    rbkn_7_pd character varying(25),
    rbkn_7_pp character varying(25),
    rbkn_7_o character varying(25),
    rbkn_7_r character varying(25),
    rbkn_7_la character varying(25),
    rbkn_7_mp character varying(25),
    rbkn_7_bop character varying(25),
    rbkn_7_tk character varying(25),
    rbkn_7_fi character varying(25),
    rbkn_7_k character varying(25),
    rbkn_7_t character varying(25),
    rbkn_8_v character varying(25),
    rbkn_8_g character varying(25),
    rbkn_8_pm character varying(25),
    rbkn_8_pb character varying(25),
    rbkn_8_pd character varying(25),
    rbkn_8_pp character varying(25),
    rbkn_8_o character varying(25),
    rbkn_8_r character varying(25),
    rbkn_8_la character varying(25),
    rbkn_8_mp character varying(25),
    rbkn_8_bop character varying(25),
    rbkn_8_tk character varying(25),
    rbkn_8_fi character varying(25),
    rbkn_8_k character varying(25),
    rbkn_8_t character varying(25),
    rbkr_1_v character varying(25),
    rbkr_1_g character varying(25),
    rbkr_1_pm character varying(25),
    rbkr_1_pb character varying(25),
    rbkr_1_pd character varying(25),
    rbkr_1_pp character varying(25),
    rbkr_1_o character varying(25),
    rbkr_1_r character varying(25),
    rbkr_1_la character varying(25),
    rbkr_1_mp character varying(25),
    rbkr_1_bop character varying(25),
    rbkr_1_tk character varying(25),
    rbkr_1_fi character varying(25),
    rbkr_1_k character varying(25),
    rbkr_1_t character varying(25),
    rbkr_2_v character varying(25),
    rbkr_2_g character varying(25),
    rbkr_2_pm character varying(25),
    rbkr_2_pb character varying(25),
    rbkr_2_pd character varying(25),
    rbkr_2_pp character varying(25),
    rbkr_2_o character varying(25),
    rbkr_2_r character varying(25),
    rbkr_2_la character varying(25),
    rbkr_2_mp character varying(25),
    rbkr_2_bop character varying(25),
    rbkr_2_tk character varying(25),
    rbkr_2_fi character varying(25),
    rbkr_2_k character varying(25),
    rbkr_2_t character varying(25),
    rbkr_3_v character varying(25),
    rbkr_3_g character varying(25),
    rbkr_3_pm character varying(25),
    rbkr_3_pb character varying(25),
    rbkr_3_pd character varying(25),
    rbkr_3_pp character varying(25),
    rbkr_3_o character varying(25),
    rbkr_3_r character varying(25),
    rbkr_3_la character varying(25),
    rbkr_3_mp character varying(25),
    rbkr_3_bop character varying(25),
    rbkr_3_tk character varying(25),
    rbkr_3_fi character varying(25),
    rbkr_3_k character varying(25),
    rbkr_3_t character varying(25),
    rbkr_4_v character varying(25),
    rbkr_4_g character varying(25),
    rbkr_4_pm character varying(25),
    rbkr_4_pb character varying(25),
    rbkr_4_pd character varying(25),
    rbkr_4_pp character varying(25),
    rbkr_4_o character varying(25),
    rbkr_4_r character varying(25),
    rbkr_4_la character varying(25),
    rbkr_4_mp character varying(25),
    rbkr_4_bop character varying(25),
    rbkr_4_tk character varying(25),
    rbkr_4_fi character varying(25),
    rbkr_4_k character varying(25),
    rbkr_4_t character varying(25),
    rbkr_5_v character varying(25),
    rbkr_5_g character varying(25),
    rbkr_5_pm character varying(25),
    rbkr_5_pb character varying(25),
    rbkr_5_pd character varying(25),
    rbkr_5_pp character varying(25),
    rbkr_5_o character varying(25),
    rbkr_5_r character varying(25),
    rbkr_5_la character varying(25),
    rbkr_5_mp character varying(25),
    rbkr_5_bop character varying(25),
    rbkr_5_tk character varying(25),
    rbkr_5_fi character varying(25),
    rbkr_5_k character varying(25),
    rbkr_5_t character varying(25),
    rbkr_6_v character varying(25),
    rbkr_6_g character varying(25),
    rbkr_6_pm character varying(25),
    rbkr_6_pb character varying(25),
    rbkr_6_pd character varying(25),
    rbkr_6_pp character varying(25),
    rbkr_6_o character varying(25),
    rbkr_6_r character varying(25),
    rbkr_6_la character varying(25),
    rbkr_6_mp character varying(25),
    rbkr_6_bop character varying(25),
    rbkr_6_tk character varying(25),
    rbkr_6_fi character varying(25),
    rbkr_6_k character varying(25),
    rbkr_6_t character varying(25),
    rbkr_7_v character varying(25),
    rbkr_7_g character varying(25),
    rbkr_7_pm character varying(25),
    rbkr_7_pb character varying(25),
    rbkr_7_pd character varying(25),
    rbkr_7_pp character varying(25),
    rbkr_7_o character varying(25),
    rbkr_7_r character varying(25),
    rbkr_7_la character varying(25),
    rbkr_7_mp character varying(25),
    rbkr_7_bop character varying(25),
    rbkr_7_tk character varying(25),
    rbkr_7_fi character varying(25),
    rbkr_7_k character varying(25),
    rbkr_7_t character varying(25),
    rbkr_8_v character varying(25),
    rbkr_8_g character varying(25),
    rbkr_8_pm character varying(25),
    rbkr_8_pb character varying(25),
    rbkr_8_pd character varying(25),
    rbkr_8_pp character varying(25),
    rbkr_8_o character varying(25),
    rbkr_8_r character varying(25),
    rbkr_8_la character varying(25),
    rbkr_8_mp character varying(25),
    rbkr_8_bop character varying(25),
    rbkr_8_tk character varying(25),
    rbkr_8_fi character varying(25),
    rbkr_8_k character varying(25),
    rbkr_8_t character varying(25),
    diagnosis_klinik character varying(25),
    gambaran_radiografis character varying(25),
    indikasi character varying(25),
    terapi text,
    keterangan text,
    prognosis_umum text,
    prognosis_lokal text,
    p1_tanggal timestamp(6) without time zone,
    p1_indeksplak_ra_el16_b character varying(25),
    p1_indeksplak_ra_el12_b character varying(25),
    p1_indeksplak_ra_el11_b character varying(25),
    p1_indeksplak_ra_el21_b character varying(25),
    p1_indeksplak_ra_el22_b character varying(25),
    p1_indeksplak_ra_el24_b character varying(25),
    p1_indeksplak_ra_el26_b character varying(25),
    p1_indeksplak_ra_el16_l character varying(25),
    p1_indeksplak_ra_el12_l character varying(25),
    p1_indeksplak_ra_el11_l character varying(25),
    p1_indeksplak_ra_el21_l character varying(25),
    p1_indeksplak_ra_el22_l character varying(25),
    p1_indeksplak_ra_el24_l character varying(25),
    p1_indeksplak_ra_el26_l character varying(25),
    p1_indeksplak_rb_el36_b character varying(25),
    p1_indeksplak_rb_el34_b character varying(25),
    p1_indeksplak_rb_el32_b character varying(25),
    p1_indeksplak_rb_el31_b character varying(25),
    p1_indeksplak_rb_el41_b character varying(25),
    p1_indeksplak_rb_el42_b character varying(25),
    p1_indeksplak_rb_el46_b character varying(25),
    p1_indeksplak_rb_el36_l character varying(25),
    p1_indeksplak_rb_el34_l character varying(25),
    p1_indeksplak_rb_el32_l character varying(25),
    p1_indeksplak_rb_el31_l character varying(25),
    p1_indeksplak_rb_el41_l character varying(25),
    p1_indeksplak_rb_el42_l character varying(25),
    p1_indeksplak_rb_el46_l character varying(25),
    p1_bop_ra_el16_b character varying(25),
    p1_bop_ra_el12_b character varying(25),
    p1_bop_ra_el11_b character varying(25),
    p1_bop_ra_el21_b character varying(25),
    p1_bop_ra_el22_b character varying(25),
    p1_bop_ra_el24_b character varying(25),
    p1_bop_ra_el26_b character varying(25),
    p1_bop_ra_el16_l character varying(25),
    p1_bop_ra_el12_l character varying(25),
    p1_bop_ra_el11_l character varying(25),
    p1_bop_ra_el21_l character varying(25),
    p1_bop_ra_el22_l character varying(25),
    p1_bop_ra_el24_l character varying(25),
    p1_bop_ra_el26_l character varying(25),
    p1_bop_rb_el36_b character varying(25),
    p1_bop_rb_el34_b character varying(25),
    p1_bop_rb_el32_b character varying(25),
    p1_bop_rb_el31_b character varying(25),
    p1_bop_rb_el41_b character varying(25),
    p1_bop_rb_el42_b character varying(25),
    p1_bop_rb_el46_b character varying(25),
    p1_bop_rb_el36_l character varying(25),
    p1_bop_rb_el34_l character varying(25),
    p1_bop_rb_el32_l character varying(25),
    p1_bop_rb_el31_l character varying(25),
    p1_bop_rb_el41_l character varying(25),
    p1_bop_rb_el42_l character varying(25),
    p1_bop_rb_el46_l character varying(25),
    p1_indekskalkulus_ra_el16_b character varying(25),
    p1_indekskalkulus_ra_el26_b character varying(25),
    p1_indekskalkulus_ra_el16_l character varying(25),
    p1_indekskalkulus_ra_el26_l character varying(25),
    p1_indekskalkulus_rb_el36_b character varying(25),
    p1_indekskalkulus_rb_el34_b character varying(25),
    p1_indekskalkulus_rb_el32_b character varying(25),
    p1_indekskalkulus_rb_el31_b character varying(25),
    p1_indekskalkulus_rb_el41_b character varying(25),
    p1_indekskalkulus_rb_el42_b character varying(25),
    p1_indekskalkulus_rb_el46_b character varying(25),
    p1_indekskalkulus_rb_el36_l character varying(25),
    p1_indekskalkulus_rb_el34_l character varying(25),
    p1_indekskalkulus_rb_el32_l character varying(25),
    p1_indekskalkulus_rb_el31_l character varying(25),
    p1_indekskalkulus_rb_el41_l character varying(25),
    p1_indekskalkulus_rb_el42_l character varying(25),
    p1_indekskalkulus_rb_el46_l character varying(25),
    p2_tanggal timestamp(6) without time zone,
    p2_indeksplak_ra_el16_b character varying(25),
    p2_indeksplak_ra_el12_b character varying(25),
    p2_indeksplak_ra_el11_b character varying(25),
    p2_indeksplak_ra_el21_b character varying(25),
    p2_indeksplak_ra_el22_b character varying(25),
    p2_indeksplak_ra_el24_b character varying(25),
    p2_indeksplak_ra_el26_b character varying(25),
    p2_indeksplak_ra_el16_l character varying(25),
    p2_indeksplak_ra_el12_l character varying(25),
    p2_indeksplak_ra_el11_l character varying(25),
    p2_indeksplak_ra_el21_l character varying(25),
    p2_indeksplak_ra_el22_l character varying(25),
    p2_indeksplak_ra_el24_l character varying(25),
    p2_indeksplak_ra_el26_l character varying(25),
    p2_indeksplak_rb_el36_b character varying(25),
    p2_indeksplak_rb_el34_b character varying(25),
    p2_indeksplak_rb_el32_b character varying(25),
    p2_indeksplak_rb_el31_b character varying(25),
    p2_indeksplak_rb_el41_b character varying(25),
    p2_indeksplak_rb_el42_b character varying(25),
    p2_indeksplak_rb_el46_b character varying(25),
    p2_indeksplak_rb_el36_l character varying(25),
    p2_indeksplak_rb_el34_l character varying(25),
    p2_indeksplak_rb_el32_l character varying(25),
    p2_indeksplak_rb_el31_l character varying(25),
    p2_indeksplak_rb_el41_l character varying(25),
    p2_indeksplak_rb_el42_l character varying(25),
    p2_indeksplak_rb_el46_l character varying(25),
    p2_bop_ra_el16_b character varying(25),
    p2_bop_ra_el12_b character varying(25),
    p2_bop_ra_el11_b character varying(25),
    p2_bop_ra_el21_b character varying(25),
    p2_bop_ra_el22_b character varying(25),
    p2_bop_ra_el24_b character varying(25),
    p2_bop_ra_el26_b character varying(25),
    p2_bop_ra_el16_l character varying(25),
    p2_bop_ra_el12_l character varying(25),
    p2_bop_ra_el11_l character varying(25),
    p2_bop_ra_el21_l character varying(25),
    p2_bop_ra_el22_l character varying(25),
    p2_bop_ra_el24_l character varying(25),
    p2_bop_ra_el26_l character varying(25),
    p2_bop_rb_el36_b character varying(25),
    p2_bop_rb_el34_b character varying(25),
    p2_bop_rb_el32_b character varying(25),
    p2_bop_rb_el31_b character varying(25),
    p2_bop_rb_el41_b character varying(25),
    p2_bop_rb_el42_b character varying(25),
    p2_bop_rb_el46_b character varying(25),
    p2_bop_rb_el36_l character varying(25),
    p2_bop_rb_el34_l character varying(25),
    p2_bop_rb_el32_l character varying(25),
    p2_bop_rb_el31_l character varying(25),
    p2_bop_rb_el41_l character varying(25),
    p2_bop_rb_el42_l character varying(25),
    p2_bop_rb_el46_l character varying(25),
    p2_indekskalkulus_ra_el16_b character varying(25),
    p2_indekskalkulus_ra_el26_b character varying(25),
    p2_indekskalkulus_ra_el16_l character varying(25),
    p2_indekskalkulus_ra_el26_l character varying(25),
    p2_indekskalkulus_rb_el36_b character varying(25),
    p2_indekskalkulus_rb_el34_b character varying(25),
    p2_indekskalkulus_rb_el32_b character varying(25),
    p2_indekskalkulus_rb_el31_b character varying(25),
    p2_indekskalkulus_rb_el41_b character varying(25),
    p2_indekskalkulus_rb_el42_b character varying(25),
    p2_indekskalkulus_rb_el46_b character varying(25),
    p2_indekskalkulus_rb_el36_l character varying(25),
    p2_indekskalkulus_rb_el34_l character varying(25),
    p2_indekskalkulus_rb_el32_l character varying(25),
    p2_indekskalkulus_rb_el31_l character varying(25),
    p2_indekskalkulus_rb_el41_l character varying(25),
    p2_indekskalkulus_rb_el42_l character varying(25),
    p2_indekskalkulus_rb_el46_l character varying(25),
    p3_tanggal timestamp(6) without time zone,
    p3_indeksplak_ra_el16_b character varying(25),
    p3_indeksplak_ra_el12_b character varying(25),
    p3_indeksplak_ra_el11_b character varying(25),
    p3_indeksplak_ra_el21_b character varying(25),
    p3_indeksplak_ra_el22_b character varying(25),
    p3_indeksplak_ra_el24_b character varying(25),
    p3_indeksplak_ra_el26_b character varying(25),
    p3_indeksplak_ra_el16_l character varying(25),
    p3_indeksplak_ra_el12_l character varying(25),
    p3_indeksplak_ra_el11_l character varying(25),
    p3_indeksplak_ra_el21_l character varying(25),
    p3_indeksplak_ra_el22_l character varying(25),
    p3_indeksplak_ra_el24_l character varying(25),
    p3_indeksplak_ra_el26_l character varying(25),
    p3_indeksplak_rb_el36_b character varying(25),
    p3_indeksplak_rb_el34_b character varying(25),
    p3_indeksplak_rb_el32_b character varying(25),
    p3_indeksplak_rb_el31_b character varying(25),
    p3_indeksplak_rb_el41_b character varying(25),
    p3_indeksplak_rb_el42_b character varying(25),
    p3_indeksplak_rb_el46_b character varying(25),
    p3_indeksplak_rb_el36_l character varying(25),
    p3_indeksplak_rb_el34_l character varying(25),
    p3_indeksplak_rb_el32_l character varying(25),
    p3_indeksplak_rb_el31_l character varying(25),
    p3_indeksplak_rb_el41_l character varying(25),
    p3_indeksplak_rb_el42_l character varying(25),
    p3_indeksplak_rb_el46_l character varying(25),
    p3_bop_ra_el16_b character varying(25),
    p3_bop_ra_el12_b character varying(25),
    p3_bop_ra_el11_b character varying(25),
    p3_bop_ra_el21_b character varying(25),
    p3_bop_ra_el22_b character varying(25),
    p3_bop_ra_el24_b character varying(25),
    p3_bop_ra_el26_b character varying(25),
    p3_bop_ra_el16_l character varying(25),
    p3_bop_ra_el12_l character varying(25),
    p3_bop_ra_el11_l character varying(25),
    p3_bop_ra_el21_l character varying(25),
    p3_bop_ra_el22_l character varying(25),
    p3_bop_ra_el24_l character varying(25),
    p3_bop_ra_el26_l character varying(25),
    p3_bop_rb_el36_b character varying(25),
    p3_bop_rb_el34_b character varying(25),
    p3_bop_rb_el32_b character varying(25),
    p3_bop_rb_el31_b character varying(25),
    p3_bop_rb_el41_b character varying(25),
    p3_bop_rb_el42_b character varying(25),
    p3_bop_rb_el46_b character varying(25),
    p3_bop_rb_el36_l character varying(25),
    p3_bop_rb_el34_l character varying(25),
    p3_bop_rb_el32_l character varying(25),
    p3_bop_rb_el31_l character varying(25),
    p3_bop_rb_el41_l character varying(25),
    p3_bop_rb_el42_l character varying(25),
    p3_bop_rb_el46_l character varying(25),
    p3_indekskalkulus_ra_el16_b character varying(25),
    p3_indekskalkulus_ra_el26_b character varying(25),
    p3_indekskalkulus_ra_el16_l character varying(25),
    p3_indekskalkulus_ra_el26_l character varying(25),
    p3_indekskalkulus_rb_el36_b character varying(25),
    p3_indekskalkulus_rb_el34_b character varying(25),
    p3_indekskalkulus_rb_el32_b character varying(25),
    p3_indekskalkulus_rb_el31_b character varying(25),
    p3_indekskalkulus_rb_el41_b character varying(25),
    p3_indekskalkulus_rb_el42_b character varying(25),
    p3_indekskalkulus_rb_el46_b character varying(25),
    p3_indekskalkulus_rb_el36_l character varying(25),
    p3_indekskalkulus_rb_el34_l character varying(25),
    p3_indekskalkulus_rb_el32_l character varying(25),
    p3_indekskalkulus_rb_el31_l character varying(25),
    p3_indekskalkulus_rb_el41_l character varying(25),
    p3_indekskalkulus_rb_el42_l character varying(25),
    p3_indekskalkulus_rb_el46_l character varying(25),
    foto_klinis_oklusi_arah_kiri character varying(225),
    foto_klinis_oklusi_arah_kanan character varying(225),
    foto_klinis_oklusi_arah_anterior character varying(225),
    foto_klinis_oklusal_rahang_atas character varying(225),
    foto_klinis_oklusal_rahang_bawah character varying(225),
    foto_klinis_before character varying(225),
    foto_klinis_after character varying(225),
    foto_ronsen_panoramik character varying(225),
    terapi_s text,
    terapi_o text,
    terapi_a text,
    terapi_p text,
    terapi_ohis character varying(25),
    terapi_bop character varying(25),
    terapi_pm18 character varying(25),
    terapi_pm17 character varying(25),
    terapi_pm16 character varying(25),
    terapi_pm15 character varying(25),
    terapi_pm14 character varying(25),
    terapi_pm13 character varying(25),
    terapi_pm12 character varying(25),
    terapi_pm11 character varying(25),
    terapi_pm21 character varying(25),
    terapi_pm22 character varying(25),
    terapi_pm23 character varying(25),
    terapi_pm24 character varying(25),
    terapi_pm25 character varying(25),
    terapi_pm26 character varying(25),
    terapi_pm27 character varying(25),
    terapi_pm28 character varying(25),
    terapi_pm38 character varying(25),
    terapi_pm37 character varying(25),
    terapi_pm36 character varying(25),
    terapi_pm35 character varying(25),
    terapi_pm34 character varying(25),
    terapi_pm33 character varying(25),
    terapi_pm32 character varying(25),
    terapi_pm31 character varying(25),
    terapi_pm41 character varying(25),
    terapi_pm42 character varying(25),
    terapi_pm43 character varying(25),
    terapi_pm44 character varying(25),
    terapi_pm45 character varying(25),
    terapi_pm46 character varying(25),
    terapi_pm47 character varying(25),
    terapi_pm48 character varying(25),
    terapi_pb18 character varying(25),
    terapi_pb17 character varying(25),
    terapi_pb16 character varying(25),
    terapi_pb15 character varying(25),
    terapi_pb14 character varying(25),
    terapi_pb13 character varying(25),
    terapi_pb12 character varying(25),
    terapi_pb11 character varying(25),
    terapi_pb21 character varying(25),
    terapi_pb22 character varying(25),
    terapi_pb23 character varying(25),
    terapi_pb24 character varying(25),
    terapi_pb25 character varying(25),
    terapi_pb26 character varying(25),
    terapi_pb27 character varying(25),
    terapi_pb28 character varying(25),
    terapi_pb38 character varying(25),
    terapi_pb37 character varying(25),
    terapi_pb36 character varying(25),
    terapi_pb35 character varying(25),
    terapi_pb34 character varying(25),
    terapi_pb33 character varying(25),
    terapi_pb32 character varying(25),
    terapi_pb31 character varying(25),
    terapi_pb41 character varying(25),
    terapi_pb42 character varying(25),
    terapi_pb43 character varying(25),
    terapi_pb44 character varying(25),
    terapi_pb45 character varying(25),
    terapi_pb46 character varying(25),
    terapi_pb47 character varying(25),
    terapi_pb48 character varying(25),
    terapi_pd18 character varying(25),
    terapi_pd17 character varying(25),
    terapi_pd16 character varying(25),
    terapi_pd15 character varying(25),
    terapi_pd14 character varying(25),
    terapi_pd13 character varying(25),
    terapi_pd12 character varying(25),
    terapi_pd11 character varying(25),
    terapi_pd21 character varying(25),
    terapi_pd22 character varying(25),
    terapi_pd23 character varying(25),
    terapi_pd24 character varying(25),
    terapi_pd25 character varying(25),
    terapi_pd26 character varying(25),
    terapi_pd27 character varying(25),
    terapi_pd28 character varying(25),
    terapi_pd38 character varying(25),
    terapi_pd37 character varying(25),
    terapi_pd36 character varying(25),
    terapi_pd35 character varying(25),
    terapi_pd34 character varying(25),
    terapi_pd33 character varying(25),
    terapi_pd32 character varying(25),
    terapi_pd31 character varying(25),
    terapi_pd41 character varying(25),
    terapi_pd42 character varying(25),
    terapi_pd43 character varying(25),
    terapi_pd44 character varying(25),
    terapi_pd45 character varying(25),
    terapi_pd46 character varying(25),
    terapi_pd47 character varying(25),
    terapi_pd48 character varying(25),
    terapi_pl18 character varying(25),
    terapi_pl17 character varying(25),
    terapi_pl16 character varying(25),
    terapi_pl15 character varying(25),
    terapi_pl14 character varying(25),
    terapi_pl13 character varying(25),
    terapi_pl12 character varying(25),
    terapi_pl11 character varying(25),
    terapi_pl21 character varying(25),
    terapi_pl22 character varying(25),
    terapi_pl23 character varying(25),
    terapi_pl24 character varying(25),
    terapi_pl25 character varying(25),
    terapi_pl26 character varying(25),
    terapi_pl27 character varying(25),
    terapi_pl28 character varying(25),
    terapi_pl38 character varying(25),
    terapi_pl37 character varying(25),
    terapi_pl36 character varying(25),
    terapi_pl35 character varying(25),
    terapi_pl34 character varying(25),
    terapi_pl33 character varying(25),
    terapi_pl32 character varying(25),
    terapi_pl31 character varying(25),
    terapi_pl41 character varying(25),
    terapi_pl42 character varying(25),
    terapi_pl43 character varying(25),
    terapi_pl44 character varying(25),
    terapi_pl45 character varying(25),
    terapi_pl46 character varying(25),
    terapi_pl47 character varying(25),
    terapi_pl48 character varying(25),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    status_emr character varying(10),
    status_penilaian character varying(10)
);


ALTER TABLE public.emrperiodonties OWNER TO rsyarsi;

--
-- TOC entry 3763 (class 0 OID 0)
-- Dependencies: 226
-- Name: COLUMN emrperiodonties.status_emr; Type: COMMENT; Schema: public; Owner: rsyarsi
--

COMMENT ON COLUMN public.emrperiodonties.status_emr IS '[ OPEN, WRITE, FINISH ]';


--
-- TOC entry 3764 (class 0 OID 0)
-- Dependencies: 226
-- Name: COLUMN emrperiodonties.status_penilaian; Type: COMMENT; Schema: public; Owner: rsyarsi
--

COMMENT ON COLUMN public.emrperiodonties.status_penilaian IS '[ OPEN, WRITE, FINISH ]';


--
-- TOC entry 227 (class 1259 OID 16491)
-- Name: emrprostodontie_logbooks; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.emrprostodontie_logbooks (
    id uuid NOT NULL,
    dateentri timestamp without time zone,
    work text NOT NULL,
    usernameentry uuid NOT NULL,
    usernameentryname character varying(250) NOT NULL,
    lectureid uuid,
    lecturename character varying(250),
    updated_at timestamp without time zone,
    created_at timestamp without time zone,
    emrid uuid,
    dateverifylecture timestamp without time zone
);


ALTER TABLE public.emrprostodontie_logbooks OWNER TO rsyarsi;

--
-- TOC entry 228 (class 1259 OID 16496)
-- Name: emrprostodonties; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.emrprostodonties (
    id uuid NOT NULL,
    noregister character varying(25),
    noepisode character varying(25),
    nomorrekammedik character varying(25),
    tanggal timestamp(0) without time zone,
    namapasien character varying(350),
    pekerjaan character varying(255),
    jeniskelamin character varying(25),
    alamatpasien text,
    namaoperator character varying(350),
    nomortelpon character varying(25),
    npm character varying(25),
    keluhanutama text,
    riwayatgeligi text,
    pengalamandengangigitiruan character varying(255),
    estetis character varying(255),
    fungsibicara character varying(255),
    penguyahan character varying(255),
    pembiayaan character varying(255),
    lainlain text,
    wajah character varying(25),
    profilmuka character varying(25),
    pupil character varying(25),
    tragus character varying(25),
    hidung character varying(25),
    pernafasanmelaluihidung character varying(25),
    bibiratas character varying(25),
    bibiratas_b character varying(25),
    bibirbawah character varying(25),
    bibirbawah_b character varying(25),
    submandibulariskanan character varying(25),
    submandibulariskanan_b character varying(25),
    submandibulariskiri character varying(25),
    submandibulariskiri_b character varying(25),
    sublingualis character varying(25),
    sublingualis_b character varying(25),
    sisikiri character varying(25),
    sisikirisejak character varying(100),
    sisikanan character varying(25),
    sisikanansejak character varying(100),
    membukamulut character varying(25),
    membukamulut_b character varying(25),
    kelainanlain text,
    higienemulut character varying(25),
    salivakuantitas character varying(25),
    salivakonsisten character varying(25),
    lidahukuran character varying(25),
    lidahposisiwright character varying(25),
    lidahmobilitas character varying(25),
    refleksmuntah character varying(25),
    mukosamulut character varying(25),
    mukosamulutberupa character varying(255),
    gigitan character varying(25),
    gigitanbilaada character varying(25),
    gigitanterbuka character varying(25),
    gigitanterbukaregion character varying(255),
    gigitansilang character varying(25),
    gigitansilangregion character varying(255),
    hubunganrahang character varying(25),
    pemeriksaanrontgendental character varying(25),
    elemengigi character varying(255),
    pemeriksaanrontgenpanoramik character varying(25),
    pemeriksaanrontgentmj character varying(25),
    frakturgigi character varying(25),
    frakturarah character varying(25),
    frakturbesar character varying(25),
    intraorallainlain text,
    perbandinganmahkotadanakargigi character varying(255),
    interprestasifotorontgen character varying(255),
    intraoralkebiasaanburuk character varying(25),
    intraoralkebiasaanburukberupa character varying(255),
    pemeriksaanodontogram_11_51 character varying(25),
    pemeriksaanodontogram_12_52 character varying(25),
    pemeriksaanodontogram_13_53 character varying(25),
    pemeriksaanodontogram_14_54 character varying(25),
    pemeriksaanodontogram_15_55 character varying(25),
    pemeriksaanodontogram_16 character varying(25),
    pemeriksaanodontogram_17 character varying(25),
    pemeriksaanodontogram_18 character varying(25),
    pemeriksaanodontogram_61_21 character varying(25),
    pemeriksaanodontogram_62_22 character varying(25),
    pemeriksaanodontogram_63_23 character varying(25),
    pemeriksaanodontogram_64_24 character varying(25),
    pemeriksaanodontogram_65_25 character varying(25),
    pemeriksaanodontogram_26 character varying(25),
    pemeriksaanodontogram_27 character varying(25),
    pemeriksaanodontogram_28 character varying(25),
    pemeriksaanodontogram_48 character varying(25),
    pemeriksaanodontogram_47 character varying(25),
    pemeriksaanodontogram_46 character varying(25),
    pemeriksaanodontogram_45_85 character varying(25),
    pemeriksaanodontogram_44_84 character varying(25),
    pemeriksaanodontogram_43_83 character varying(25),
    pemeriksaanodontogram_42_82 character varying(25),
    pemeriksaanodontogram_41_81 character varying(25),
    pemeriksaanodontogram_38 character varying(25),
    pemeriksaanodontogram_37 character varying(25),
    pemeriksaanodontogram_36 character varying(25),
    pemeriksaanodontogram_75_35 character varying(25),
    pemeriksaanodontogram_74_34 character varying(25),
    pemeriksaanodontogram_73_33 character varying(25),
    pemeriksaanodontogram_72_32 character varying(25),
    pemeriksaanodontogram_71_31 character varying(25),
    rahangataspostkiri character varying(25),
    rahangataspostkanan character varying(25),
    rahangatasanterior character varying(25),
    rahangbawahpostkiri character varying(25),
    rahangbawahpostkanan character varying(25),
    rahangbawahanterior character varying(25),
    rahangatasbentukpostkiri character varying(25),
    rahangatasbentukpostkanan character varying(25),
    rahangatasbentukanterior character varying(25),
    rahangatasketinggianpostkiri character varying(25),
    rahangatasketinggianpostkanan character varying(25),
    rahangatasketinggiananterior character varying(25),
    rahangatastahananjaringanpostkiri character varying(25),
    rahangatastahananjaringanpostkanan character varying(25),
    rahangatastahananjaringananterior character varying(25),
    rahangatasbentukpermukaanpostkiri character varying(25),
    rahangatasbentukpermukaanpostkanan character varying(25),
    rahangatasbentukpermukaananterior character varying(25),
    rahangbawahbentukpostkiri character varying(25),
    rahangbawahbentukpostkanan character varying(25),
    rahangbawahbentukanterior character varying(25),
    rahangbawahketinggianpostkiri character varying(25),
    rahangbawahketinggianpostkanan character varying(25),
    rahangbawahketinggiananterior character varying(25),
    rahangbawahtahananjaringanpostkiri character varying(25),
    rahangbawahtahananjaringanpostkanan character varying(25),
    rahangbawahtahananjaringananterior character varying(25),
    rahangbawahbentukpermukaanpostkiri character varying(25),
    rahangbawahbentukpermukaanpostkanan character varying(25),
    rahangbawahbentukpermukaananterior character varying(25),
    anterior character varying(25),
    prosteriorkiri character varying(25),
    prosteriorkanan character varying(25),
    labialissuperior character varying(25),
    labialisinferior character varying(25),
    bukalisrahangataskiri character varying(25),
    bukalisrahangataskanan character varying(25),
    bukalisrahangbawahkiri character varying(25),
    bukalisrahangbawahkanan character varying(25),
    lingualis character varying(25),
    palatum character varying(25),
    kedalaman character varying(25),
    toruspalatinus character varying(25),
    palatummolle character varying(25),
    tuberorositasalveolariskiri character varying(25),
    tuberorositasalveolariskanan character varying(25),
    ruangretromilahioidkiri character varying(25),
    ruangretromilahioidkanan character varying(25),
    bentuklengkungrahangatas character varying(25),
    bentuklengkungrahangbawah character varying(25),
    perlekatandasarmulut character varying(25),
    pemeriksaanlain_lainlain text,
    sikapmental character varying(25),
    diagnosa text,
    rahangatas character varying(25),
    rahangataselemen character varying(255),
    rahangbawah character varying(25),
    rahangbawahelemen character varying(255),
    gigitiruancekat character varying(25),
    gigitiruancekatelemen character varying(255),
    perawatanperiodontal character varying(25),
    perawatanbedah character varying(25),
    perawatanbedah_ada character varying(25),
    perawatanbedahelemen character varying(25),
    perawatanbedahlainlain text,
    konservasigigi character varying(25),
    konservasigigielemen character varying(255),
    rekonturing character varying(25),
    adapembuatanmahkota character varying(255),
    pengasahangigimiring character varying(255),
    pengasahangigiextruded character varying(255),
    rekonturinglainlain text,
    macamcetakan_ra character varying(25),
    acamcetakan_rb character varying(25),
    warnagigi character varying(255),
    klasifikasidaerahtidakbergigirahangatas character varying(255),
    klasifikasidaerahtidakbergigirahangbawah character varying(255),
    gigipenyangga character varying(255),
    direk character varying(255),
    indirek character varying(255),
    platdasar character varying(255),
    anasirgigi character varying(255),
    prognosis character varying(25),
    prognosisalasan text,
    reliningregio character varying(255),
    reliningregiotanggal timestamp(0) without time zone,
    reparasiregio character varying(25),
    reparasiregiotanggal timestamp(0) without time zone,
    perawatanulangsebab character varying(255),
    perawatanulanglainlain character varying(255),
    perawatanulanglainlaintanggal timestamp(0) without time zone,
    perawatanulangketerangan text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    nim character varying(25),
    designngigi text,
    designngigitext text,
    fotoodontogram text,
    status_emr character varying(10),
    status_penilaian character varying(10)
);


ALTER TABLE public.emrprostodonties OWNER TO rsyarsi;

--
-- TOC entry 3765 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN emrprostodonties.status_emr; Type: COMMENT; Schema: public; Owner: rsyarsi
--

COMMENT ON COLUMN public.emrprostodonties.status_emr IS '[ OPEN, WRITE, FINISH ]';


--
-- TOC entry 3766 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN emrprostodonties.status_penilaian; Type: COMMENT; Schema: public; Owner: rsyarsi
--

COMMENT ON COLUMN public.emrprostodonties.status_penilaian IS '[ OPEN, WRITE, FINISH ]';


--
-- TOC entry 229 (class 1259 OID 16501)
-- Name: emrradiologies; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.emrradiologies (
    id uuid NOT NULL,
    noepisode character varying(20),
    noregistrasi character varying(15),
    nomr character varying(8),
    namapasien character varying(255),
    alamat text,
    usia character varying(3),
    tglpotret date,
    diagnosaklinik text,
    foto text,
    jenisradiologi character varying(25),
    periaprikal_int_mahkota text,
    periaprikal_int_akar text,
    periaprikal_int_membran text,
    periaprikal_int_lamina_dura text,
    periaprikal_int_furkasi text,
    periaprikal_int_alveoral text,
    periaprikal_int_kondisi_periaprikal text,
    periaprikal_int_kesan text,
    periaprikal_int_lesigigi text,
    periaprikal_int_suspek text,
    nim character varying(20),
    namaoperator character varying(250),
    namadokter character varying(250),
    panoramik_miising_teeth text,
    panoramik_missing_agnesia text,
    panoramik_persistensi text,
    panoramik_impaki text,
    panoramik_kondisi_mahkota text,
    panoramik_kondisi_akar text,
    panoramik_kondisi_alveoral text,
    panoramik_kondisi_periaprikal text,
    panoramik_area_dua text,
    oklusal_kesan text,
    oklusal_suspek_radiognosis text,
    status_emr character varying(10),
    status_penilaian character varying(10),
    jenis_radiologi character varying(32),
    url text
);


ALTER TABLE public.emrradiologies OWNER TO rsyarsi;

--
-- TOC entry 3767 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN emrradiologies.status_emr; Type: COMMENT; Schema: public; Owner: rsyarsi
--

COMMENT ON COLUMN public.emrradiologies.status_emr IS '[ OPEN, WRITE, FINISH ]';


--
-- TOC entry 3768 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN emrradiologies.status_penilaian; Type: COMMENT; Schema: public; Owner: rsyarsi
--

COMMENT ON COLUMN public.emrradiologies.status_penilaian IS '[ OPEN, WRITE, FINISH ]';


--
-- TOC entry 230 (class 1259 OID 16506)
-- Name: failed_jobs; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.failed_jobs (
    id bigint NOT NULL,
    uuid character varying(255) NOT NULL,
    connection text NOT NULL,
    queue text NOT NULL,
    payload text NOT NULL,
    exception text NOT NULL,
    failed_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.failed_jobs OWNER TO rsyarsi;

--
-- TOC entry 231 (class 1259 OID 16512)
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: rsyarsi
--

CREATE SEQUENCE public.failed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.failed_jobs_id_seq OWNER TO rsyarsi;

--
-- TOC entry 3769 (class 0 OID 0)
-- Dependencies: 231
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rsyarsi
--

ALTER SEQUENCE public.failed_jobs_id_seq OWNED BY public.failed_jobs.id;


--
-- TOC entry 232 (class 1259 OID 16513)
-- Name: finalassesment_konservasis; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.finalassesment_konservasis (
    uuid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    nim character varying(15),
    name character varying(250),
    kelompok character varying(20),
    tumpatan_komposisi_1 numeric,
    tumpatan_komposisi_2 numeric,
    tumpatan_komposisi_3 numeric,
    tumpatan_komposisi_4 numeric,
    tumpatan_komposisi_5 numeric,
    totalakhir numeric,
    grade character varying(5),
    keterangan_grade character varying(150),
    yearid uuid,
    semesterid uuid,
    studentid uuid
);


ALTER TABLE public.finalassesment_konservasis OWNER TO rsyarsi;

--
-- TOC entry 233 (class 1259 OID 16519)
-- Name: finalassesment_orthodonties; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.finalassesment_orthodonties (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    nim character varying(50),
    name character varying(250),
    kelompok character varying(250),
    anamnesis numeric,
    foto_oi numeric,
    cetak_rahang numeric,
    modelstudi_one numeric,
    analisissefalometri numeric,
    fotografi_oral numeric,
    rencana_perawatan numeric,
    insersi_alat numeric,
    aktivasi_alat numeric,
    kontrol numeric,
    model_studi_2 numeric,
    penilaian_hasil_perawatan numeric,
    laporan_khusus numeric,
    totalakhir numeric,
    grade character varying(10),
    keterangan_grade character varying(100),
    nilaipekerjaanklinik numeric,
    nilailaporankasus numeric,
    analisismodel numeric,
    yearid uuid,
    semesterid uuid,
    studentid uuid
);


ALTER TABLE public.finalassesment_orthodonties OWNER TO rsyarsi;

--
-- TOC entry 234 (class 1259 OID 16525)
-- Name: finalassesment_periodonties; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.finalassesment_periodonties (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    nim character varying(150),
    name character varying(250),
    kelompok character varying(15),
    anamnesis_scalingmanual numeric,
    anamnesis_uss numeric,
    uss_desensitisasi numeric,
    splinting_fiber numeric,
    diskusi_tatapmuka numeric,
    dops numeric,
    totalakhir numeric,
    grade character varying(5),
    keterangan_grade character varying(25),
    yearid uuid,
    semesterid uuid,
    studentid uuid
);


ALTER TABLE public.finalassesment_periodonties OWNER TO rsyarsi;

--
-- TOC entry 235 (class 1259 OID 16531)
-- Name: finalassesment_prostodonties; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.finalassesment_prostodonties (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    nim character varying(150),
    name character varying(250),
    kelompok character varying(15),
    penyajian_diskusi numeric,
    gigi_tiruan_lepas numeric,
    dops_fungsional numeric,
    totalakhir numeric,
    grade character varying(5),
    keterangan_grade character varying(25),
    yearid uuid,
    semesterid uuid,
    studentid uuid
);


ALTER TABLE public.finalassesment_prostodonties OWNER TO rsyarsi;

--
-- TOC entry 236 (class 1259 OID 16537)
-- Name: finalassesment_radiologies; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.finalassesment_radiologies (
    uuid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    nim character varying(15),
    name character varying(250),
    kelompok character varying(20),
    videoteknikradiografi_periapikalbisektris numeric,
    videoteknikradiografi_oklusal numeric,
    interpretasi_foto_periapikal numeric,
    interpretasi_foto_panoramik numeric,
    interpretasi_foto_oklusal numeric,
    rujukan_medik numeric,
    penyaji_jr numeric,
    dops numeric,
    ujian_bagian numeric,
    totalakhir numeric,
    grade character varying(5),
    keterangan_grade character varying(150),
    yearid uuid,
    semesterid uuid,
    studentid uuid
);


ALTER TABLE public.finalassesment_radiologies OWNER TO rsyarsi;

--
-- TOC entry 237 (class 1259 OID 16543)
-- Name: hospitals; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.hospitals (
    id uuid NOT NULL,
    name character varying(250) NOT NULL,
    active integer DEFAULT 1 NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.hospitals OWNER TO rsyarsi;

--
-- TOC entry 238 (class 1259 OID 16547)
-- Name: lectures; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.lectures (
    id uuid NOT NULL,
    specialistid uuid NOT NULL,
    name character varying(150) NOT NULL,
    doctotidsimrs integer NOT NULL,
    active integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    nim character varying(25)
);


ALTER TABLE public.lectures OWNER TO rsyarsi;

--
-- TOC entry 239 (class 1259 OID 16550)
-- Name: migrations; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE public.migrations OWNER TO rsyarsi;

--
-- TOC entry 240 (class 1259 OID 16553)
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: rsyarsi
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.migrations_id_seq OWNER TO rsyarsi;

--
-- TOC entry 3770 (class 0 OID 0)
-- Dependencies: 240
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rsyarsi
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- TOC entry 241 (class 1259 OID 16554)
-- Name: password_resets; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.password_resets (
    email character varying(255) NOT NULL,
    token character varying(255) NOT NULL,
    created_at timestamp(0) without time zone
);


ALTER TABLE public.password_resets OWNER TO rsyarsi;

--
-- TOC entry 242 (class 1259 OID 16559)
-- Name: patients; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.patients (
    noepisode character varying(35),
    noregistrasi character varying(25) NOT NULL,
    nomr character varying(8),
    patientname character varying(255),
    namajaminan character varying(190),
    noantrianall character varying(10),
    gander character varying(2),
    date_of_birth date,
    address text,
    idunit integer,
    visit_date timestamp without time zone,
    namaunit character varying(250),
    iddokter integer,
    namadokter character varying(255),
    patienttype character varying(30),
    statusid integer,
    created_at timestamp without time zone
);


ALTER TABLE public.patients OWNER TO rsyarsi;

--
-- TOC entry 243 (class 1259 OID 16564)
-- Name: personal_access_tokens; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.personal_access_tokens (
    id bigint NOT NULL,
    tokenable_type character varying(255) NOT NULL,
    tokenable_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    token character varying(64) NOT NULL,
    abilities text,
    last_used_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.personal_access_tokens OWNER TO rsyarsi;

--
-- TOC entry 244 (class 1259 OID 16569)
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: rsyarsi
--

CREATE SEQUENCE public.personal_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.personal_access_tokens_id_seq OWNER TO rsyarsi;

--
-- TOC entry 3771 (class 0 OID 0)
-- Dependencies: 244
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rsyarsi
--

ALTER SEQUENCE public.personal_access_tokens_id_seq OWNED BY public.personal_access_tokens.id;


--
-- TOC entry 245 (class 1259 OID 16570)
-- Name: semesters; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.semesters (
    id uuid NOT NULL,
    semestername character varying(15) NOT NULL,
    semestervalue integer NOT NULL,
    active integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.semesters OWNER TO rsyarsi;

--
-- TOC entry 246 (class 1259 OID 16573)
-- Name: specialistgroups; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.specialistgroups (
    id uuid NOT NULL,
    name character varying(50) NOT NULL,
    active integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.specialistgroups OWNER TO rsyarsi;

--
-- TOC entry 247 (class 1259 OID 16576)
-- Name: specialists; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.specialists (
    id uuid NOT NULL,
    specialistname character varying(150) NOT NULL,
    groupspecialistid uuid NOT NULL,
    active integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    simrsid integer
);


ALTER TABLE public.specialists OWNER TO rsyarsi;

--
-- TOC entry 248 (class 1259 OID 16579)
-- Name: students; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.students (
    id uuid NOT NULL,
    name character varying(250) NOT NULL,
    nim character varying(50) NOT NULL,
    semesterid uuid NOT NULL,
    specialistid uuid NOT NULL,
    datein date NOT NULL,
    university uuid NOT NULL,
    hospitalfrom uuid NOT NULL,
    hospitalto uuid NOT NULL,
    active integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.students OWNER TO rsyarsi;

--
-- TOC entry 249 (class 1259 OID 16582)
-- Name: trsassesments; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.trsassesments (
    id uuid NOT NULL,
    assesmentgroupid uuid NOT NULL,
    studentid uuid NOT NULL,
    lectureid uuid NOT NULL,
    yearid uuid NOT NULL,
    semesterid uuid NOT NULL,
    specialistid uuid NOT NULL,
    transactiondate timestamp(0) without time zone NOT NULL,
    grandotal numeric NOT NULL,
    assesmenttype integer NOT NULL,
    active integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    idspecialistsimrs integer,
    totalbobot integer DEFAULT 0,
    assesmentfinalvalue numeric,
    lock integer DEFAULT 0,
    datelock timestamp without time zone,
    usernamelock character varying(250),
    countvisits integer
);


ALTER TABLE public.trsassesments OWNER TO rsyarsi;

--
-- TOC entry 250 (class 1259 OID 16589)
-- Name: type_one_control_trsdetailassesments; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.type_one_control_trsdetailassesments (
    id uuid NOT NULL,
    trsassesmentid uuid NOT NULL,
    assesmentdetailid uuid NOT NULL,
    assesmentdescription text NOT NULL,
    transactiondate timestamp(0) without time zone,
    controlaction text,
    assementvalue integer,
    active integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    kodesub integer
);


ALTER TABLE public.type_one_control_trsdetailassesments OWNER TO rsyarsi;

--
-- TOC entry 251 (class 1259 OID 16594)
-- Name: trassesmentdetailtypeonecontrol; Type: VIEW; Schema: public; Owner: rsyarsi
--

CREATE VIEW public.trassesmentdetailtypeonecontrol AS
 SELECT a.id,
    a.trsassesmentid,
    a.assesmentdetailid,
    b.assesmentnumbers,
    d.assementgroupname,
    a.assesmentdescription,
    a.assementvalue,
    b.assesmentbobotvalue,
    b.assesmentvaluestart,
    b.assesmentvalueend,
    a.updated_at,
    a.created_at,
    c.assesmenttype,
    b.index_sub,
    b.kode_sub_name,
    b.kodesub,
    c.assesmentgroupid
   FROM (((public.type_one_control_trsdetailassesments a
     JOIN public.assesmentdetails b ON ((a.assesmentdetailid = b.id)))
     JOIN public.trsassesments c ON ((c.id = a.trsassesmentid)))
     JOIN public.assesmentgroups d ON ((d.id = c.assesmentgroupid)));


ALTER TABLE public.trassesmentdetailtypeonecontrol OWNER TO rsyarsi;

--
-- TOC entry 252 (class 1259 OID 16599)
-- Name: type_five_trsdetailassesments; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.type_five_trsdetailassesments (
    id uuid NOT NULL,
    trsassesmentid uuid NOT NULL,
    assesmentdetailid uuid NOT NULL,
    assesmentdescription text NOT NULL,
    transactiondate timestamp(0) without time zone,
    assesmentbobotvalue integer NOT NULL,
    assesmentscore numeric NOT NULL,
    active integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    assementvalue integer,
    kodesub integer,
    norm character varying(10),
    namapasien character varying(255),
    nilaitindakan_awal numeric,
    nilaisikap_awal numeric,
    nilaitindakan_akhir numeric,
    nilaisikap_akhir numeric,
    assesmentvalue_kondite numeric
);


ALTER TABLE public.type_five_trsdetailassesments OWNER TO rsyarsi;

--
-- TOC entry 253 (class 1259 OID 16604)
-- Name: trsassesmentdetailtypefive; Type: VIEW; Schema: public; Owner: rsyarsi
--

CREATE VIEW public.trsassesmentdetailtypefive AS
 SELECT a.id,
    a.trsassesmentid,
    a.assesmentdetailid,
    b.assesmentnumbers,
    d.assementgroupname,
    a.assesmentdescription,
    a.assementvalue,
    a.assesmentscore AS assementscore,
    b.assesmentbobotvalue,
    b.assesmentvaluestart,
    b.assesmentvalueend,
    a.updated_at,
    a.created_at,
    c.assesmenttype,
    b.index_sub,
    b.kode_sub_name,
    b.kodesub,
    d.bobotprosenfinal,
    a.nilaitindakan_awal,
    a.nilaitindakan_akhir,
    a.nilaisikap_awal,
    a.nilaisikap_akhir
   FROM (((public.type_five_trsdetailassesments a
     JOIN public.assesmentdetails b ON ((a.assesmentdetailid = b.id)))
     JOIN public.trsassesments c ON ((c.id = a.trsassesmentid)))
     JOIN public.assesmentgroups d ON ((d.id = c.assesmentgroupid)));


ALTER TABLE public.trsassesmentdetailtypefive OWNER TO rsyarsi;

--
-- TOC entry 254 (class 1259 OID 16609)
-- Name: type_four_trsdetailassesments; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.type_four_trsdetailassesments (
    id uuid NOT NULL,
    trsassesmentid uuid NOT NULL,
    assesmentdetailid uuid NOT NULL,
    assesmentdescription text NOT NULL,
    transactiondate timestamp(0) without time zone,
    assesmentskala text,
    assesmentscore integer,
    active integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    assementvalue integer,
    kodesub integer
);


ALTER TABLE public.type_four_trsdetailassesments OWNER TO rsyarsi;

--
-- TOC entry 255 (class 1259 OID 16614)
-- Name: trsassesmentdetailtypefour; Type: VIEW; Schema: public; Owner: rsyarsi
--

CREATE VIEW public.trsassesmentdetailtypefour AS
 SELECT a.id,
    a.trsassesmentid,
    a.assesmentdetailid,
    b.assesmentnumbers,
    d.assementgroupname,
    a.assesmentdescription,
    a.assementvalue,
    a.assesmentscore AS assementscore,
    b.assesmentskalavalue,
    b.assesmentskalavaluestart,
    b.assesmentskalavalueend,
    a.updated_at,
    a.created_at,
    c.assesmenttype,
    b.index_sub,
    b.kode_sub_name,
    b.kodesub,
    c.assesmentgroupid,
    d.bobotprosenfinal
   FROM (((public.type_four_trsdetailassesments a
     JOIN public.assesmentdetails b ON ((a.assesmentdetailid = b.id)))
     JOIN public.trsassesments c ON ((c.id = a.trsassesmentid)))
     JOIN public.assesmentgroups d ON ((d.id = c.assesmentgroupid)));


ALTER TABLE public.trsassesmentdetailtypefour OWNER TO rsyarsi;

--
-- TOC entry 256 (class 1259 OID 16619)
-- Name: type_one_trsdetailassesments; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.type_one_trsdetailassesments (
    id uuid NOT NULL,
    trsassesmentid uuid NOT NULL,
    assesmentdetailid uuid NOT NULL,
    assesmentdescription text NOT NULL,
    transactiondate timestamp(0) without time zone,
    assesmentbobotvalue integer NOT NULL,
    assesmentskala text,
    assementscore integer NOT NULL,
    active integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    assementvalue integer,
    kodesub bigint
);


ALTER TABLE public.type_one_trsdetailassesments OWNER TO rsyarsi;

--
-- TOC entry 257 (class 1259 OID 16624)
-- Name: trsassesmentdetailtypeone; Type: VIEW; Schema: public; Owner: rsyarsi
--

CREATE VIEW public.trsassesmentdetailtypeone AS
 SELECT a.id,
    a.trsassesmentid,
    a.assesmentdetailid,
    b.assesmentnumbers,
    d.assementgroupname,
    a.assesmentdescription,
    a.assementvalue,
    a.assementscore,
    b.assesmentbobotvalue,
    b.assesmentvaluestart,
    b.assesmentvalueend,
    a.updated_at,
    a.created_at,
    c.assesmenttype,
    b.index_sub,
    b.kode_sub_name,
    b.kodesub,
    d.bobotprosenfinal
   FROM (((public.type_one_trsdetailassesments a
     JOIN public.assesmentdetails b ON ((a.assesmentdetailid = b.id)))
     JOIN public.trsassesments c ON ((c.id = a.trsassesmentid)))
     JOIN public.assesmentgroups d ON ((d.id = c.assesmentgroupid)));


ALTER TABLE public.trsassesmentdetailtypeone OWNER TO rsyarsi;

--
-- TOC entry 258 (class 1259 OID 16629)
-- Name: type_three_trsdetailassesments; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.type_three_trsdetailassesments (
    id uuid NOT NULL,
    trsassesmentid uuid NOT NULL,
    assesmentdetailid uuid NOT NULL,
    assesmentdescription text NOT NULL,
    transactiondate timestamp(0) without time zone,
    assesmentskala text,
    assesmentbobotvalue integer,
    assesmentvalue integer,
    konditevalue text,
    assesmentscore integer NOT NULL,
    active integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    assementvalue integer,
    kodesub bigint
);


ALTER TABLE public.type_three_trsdetailassesments OWNER TO rsyarsi;

--
-- TOC entry 259 (class 1259 OID 16634)
-- Name: trsassesmentdetailtypethree; Type: VIEW; Schema: public; Owner: rsyarsi
--

CREATE VIEW public.trsassesmentdetailtypethree AS
 SELECT a.id,
    a.trsassesmentid,
    a.assesmentdetailid,
    b.assesmentnumbers,
    d.assementgroupname,
    a.assesmentdescription,
    a.assementvalue,
    a.assesmentscore AS assementscore,
    b.assesmentskalavalue,
    b.assesmentskalavaluestart,
    b.assesmentskalavalueend,
    b.assesmentkonditevalue,
    b.assesmentkonditevaluestart,
    b.assesmentkonditevalueend,
    a.updated_at,
    a.created_at,
    c.assesmenttype,
    b.index_sub,
    b.kode_sub_name,
    b.kodesub,
    d.bobotprosenfinal
   FROM (((public.type_three_trsdetailassesments a
     JOIN public.assesmentdetails b ON ((a.assesmentdetailid = b.id)))
     JOIN public.trsassesments c ON ((c.id = a.trsassesmentid)))
     JOIN public.assesmentgroups d ON ((d.id = c.assesmentgroupid)));


ALTER TABLE public.trsassesmentdetailtypethree OWNER TO rsyarsi;

--
-- TOC entry 260 (class 1259 OID 16639)
-- Name: universities; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.universities (
    id uuid NOT NULL,
    name character varying(250) NOT NULL,
    active integer DEFAULT 1 NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.universities OWNER TO rsyarsi;

--
-- TOC entry 261 (class 1259 OID 16643)
-- Name: users; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    role character varying(255) NOT NULL,
    username character varying(255) NOT NULL,
    access_token text,
    expired_at timestamp(0) without time zone,
    email character varying(255) NOT NULL,
    email_verified_at timestamp(0) without time zone,
    password character varying(255) NOT NULL,
    remember_token character varying(100),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.users OWNER TO rsyarsi;

--
-- TOC entry 262 (class 1259 OID 16648)
-- Name: view_history_emrkonservasis; Type: VIEW; Schema: public; Owner: rsyarsi
--

CREATE VIEW public.view_history_emrkonservasis AS
 SELECT emrkonservasis.id,
    emrkonservasis.noregister,
    emrkonservasis.noepisode,
    emrkonservasis.nomorrekammedik,
    emrkonservasis.tanggal,
    emrkonservasis.namapasien,
    emrkonservasis.pekerjaan,
    emrkonservasis.jeniskelamin,
    emrkonservasis.alamatpasien,
    emrkonservasis.nomortelpon,
    emrkonservasis.namaoperator,
    emrkonservasis.nim,
    emrkonservasis.sblmperawatanpemeriksaangigi_18_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_17_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_16_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_15_55_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_14_54_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_13_53_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_12_52_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_11_51_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_21_61_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_22_62_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_23_63_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_24_64_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_25_65_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_26_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_27_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_28_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_18_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_17_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_16_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_15_55_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_14_54_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_13_53_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_12_52_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_11_51_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_21_61_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_22_62_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_23_63_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_24_64_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_25_65_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_26_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_27_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_28_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_18_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_17_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_16_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_15_55_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_14_54_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_13_53_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_12_52_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_11_51_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_21_61_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_22_62_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_23_63_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_24_64_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_25_65_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_26_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_27_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_28_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_41_81_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_42_82_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_43_83_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_44_84_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_45_85_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_46_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_47_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_48_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_38_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_37_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_36_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_35_75_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_34_74_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_33_73_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_32_72_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_31_71_tv,
    emrkonservasis.sblmperawatanpemeriksaangigi_41_81_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_42_82_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_43_83_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_44_84_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_45_85_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_46_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_47_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_48_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_38_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_37_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_36_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_35_75_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_34_74_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_33_73_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_32_72_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_31_71_diagnosis,
    emrkonservasis.sblmperawatanpemeriksaangigi_41_81_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_42_82_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_43_83_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_44_84_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_45_85_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_46_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_47_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_48_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_38_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_37_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_36_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_35_75_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_34_74_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_33_73_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_32_72_rencanaperawatan,
    emrkonservasis.sblmperawatanpemeriksaangigi_31_71_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_18_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_17_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_16_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_15_55_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_14_54_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_13_53_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_12_52_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_11_51_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_21_61_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_22_62_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_23_63_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_24_64_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_25_65_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_26_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_27_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_28_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_18_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_17_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_16_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_15_55_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_14_54_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_13_53_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_12_52_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_11_51_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_21_61_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_22_62_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_23_63_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_24_64_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_25_65_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_26_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_27_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_28_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_18_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_17_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_16_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_15_55_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_14_54_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_13_53_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_12_52_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_11_51_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_21_61_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_22_62_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_23_63_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_24_64_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_25_65_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_26_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_27_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_28_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_41_81_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_42_82_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_43_83_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_44_84_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_45_85_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_46_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_47_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_48_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_38_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_37_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_36_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_35_75_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_34_74_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_33_73_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_32_72_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_31_71_tv,
    emrkonservasis.ssdhperawatanpemeriksaangigi_41_81_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_42_82_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_43_83_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_44_84_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_45_85_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_46_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_47_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_48_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_38_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_37_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_36_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_35_75_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_34_74_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_33_73_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_32_72_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_31_71_diagnosis,
    emrkonservasis.ssdhperawatanpemeriksaangigi_41_81_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_42_82_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_43_83_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_44_84_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_45_85_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_46_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_47_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_48_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_38_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_37_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_36_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_35_75_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_34_74_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_33_73_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_32_72_rencanaperawatan,
    emrkonservasis.ssdhperawatanpemeriksaangigi_31_71_rencanaperawatan,
    emrkonservasis.sblmperawatanfaktorrisikokaries_sikap,
    emrkonservasis.sblmperawatanfaktorrisikokaries_status,
    emrkonservasis.sblmperawatanfaktorrisikokaries_saliva_tanpastimulasi_hidrasi,
    emrkonservasis.sblmperawatanfaktorrisikokaries_saliva_tanpastimulasi_viskosita,
    emrkonservasis."sblmperawatanfaktorrisikokaries_saliva_tanpastimulasi_pH",
    emrkonservasis.sblmperawatanfaktorrisikokaries_saliva_denganstimulasi_hidrasi,
    emrkonservasis.sblmperawatanfaktorrisikokaries_saliva_denganstimulasi_kecepata,
    emrkonservasis.sblmperawatanfaktorrisikokaries_saliva_denganstimulasi_kapasita,
    emrkonservasis."sblmperawatanfaktorrisikokaries_saliva_denganstimulasi_pH",
    emrkonservasis."sblmperawatanfaktorrisikokaries_plak_pH",
    emrkonservasis.sblmperawatanfaktorrisikokaries_plak_aktivitas,
    emrkonservasis.sblmperawatanfaktorrisikokaries_fluor_pastagigi,
    emrkonservasis.sblmperawatanfaktorrisikokaries_diet_gula,
    emrkonservasis.sblmperawatanfaktorrisikokaries_faktormodifikasi_obatpeningkata,
    emrkonservasis.sblmperawatanfaktorrisikokaries_faktormodifikasi_penyakitpenyeb,
    emrkonservasis.sblmperawatanfaktorrisikokaries_faktormodifikasi_protesa,
    emrkonservasis.sblmperawatanfaktorrisikokaries_faktormodifikasi_kariesaktif,
    emrkonservasis.sblmperawatanfaktorrisikokaries_faktormodifikasi_sikap,
    emrkonservasis.sblmperawatanfaktorrisikokaries_faktormodifikasi_keterangan,
    emrkonservasis.sblmperawatanfaktorrisikokaries_penilaianakhir_saliva,
    emrkonservasis.sblmperawatanfaktorrisikokaries_penilaianakhir_plak,
    emrkonservasis.sblmperawatanfaktorrisikokaries_penilaianakhir_diet,
    emrkonservasis.sblmperawatanfaktorrisikokaries_penilaianakhir_fluor,
    emrkonservasis.sblmperawatanfaktorrisikokaries_penilaianakhir_faktormodifikasi,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_sikap,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_status,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_saliva_tanpastimulasi_hidrasi,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_saliva_tanpastimulasi_viskosita,
    emrkonservasis."ssdhperawatanfaktorrisikokaries_saliva_tanpastimulasi_pH",
    emrkonservasis.ssdhperawatanfaktorrisikokaries_saliva_denganstimulasi_hidrasi,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_saliva_denganstimulasi_kecepata,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_saliva_denganstimulasi_kapasita,
    emrkonservasis."ssdhperawatanfaktorrisikokaries_saliva_denganstimulasi_pH",
    emrkonservasis."ssdhperawatanfaktorrisikokaries_plak_pH",
    emrkonservasis.ssdhperawatanfaktorrisikokaries_plak_aktivitas,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_fluor_pastagigi,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_diet_gula,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_faktormodifikasi_obatpeningkata,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_faktormodifikasi_penyakitpenyeb,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_faktormodifikasi_protesa,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_faktormodifikasi_kariesaktif,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_faktormodifikasi_sikap,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_faktormodifikasi_keterangan,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_penilaianakhir_saliva,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_penilaianakhir_plak,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_penilaianakhir_diet,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_penilaianakhir_fluor,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_penilaianakhir_faktormodifikasi,
    emrkonservasis.sikatgigi2xsehari,
    emrkonservasis.sikatgigi3xsehari,
    emrkonservasis.flossingsetiaphari,
    emrkonservasis.sikatinterdental,
    emrkonservasis.agenantibakteri_obatkumur,
    emrkonservasis.guladancemilandiantarawaktumakanutama,
    emrkonservasis.minumanasamtinggi,
    emrkonservasis.minumanberkafein,
    emrkonservasis.meningkatkanasupanair,
    emrkonservasis.obatkumurbakingsoda,
    emrkonservasis.konsumsimakananminumanberbahandasarsusu,
    emrkonservasis.permenkaretxylitolccpacp,
    emrkonservasis.pastagigi,
    emrkonservasis.kumursetiaphari,
    emrkonservasis.kumursetiapminggu,
    emrkonservasis.gelsetiaphari,
    emrkonservasis.gelsetiapminggu,
    emrkonservasis.perlu,
    emrkonservasis.tidakperlu,
    emrkonservasis.evaluasi_sikatgigi2xsehari,
    emrkonservasis.evaluasi_sikatgigi3xsehari,
    emrkonservasis.evaluasi_flossingsetiaphari,
    emrkonservasis.evaluasi_sikatinterdental,
    emrkonservasis.evaluasi_agenantibakteri_obatkumur,
    emrkonservasis.evaluasi_guladancemilandiantarawaktumakanutama,
    emrkonservasis.evaluasi_minumanasamtinggi,
    emrkonservasis.evaluasi_minumanberkafein,
    emrkonservasis.evaluasi_meningkatkanasupanair,
    emrkonservasis.evaluasi_obatkumurbakingsoda,
    emrkonservasis.evaluasi_konsumsimakananminumanberbahandasarsusu,
    emrkonservasis.evaluasi_permenkaretxylitolccpacp,
    emrkonservasis.evaluasi_pastagigi,
    emrkonservasis.evaluasi_kumursetiaphari,
    emrkonservasis.evaluasi_kumursetiapminggu,
    emrkonservasis.evaluasi_gelsetiaphari,
    emrkonservasis.evaluasi_gelsetiapminggu,
    emrkonservasis.evaluasi_perlu,
    emrkonservasis.evaluasi_tidakperlu,
    emrkonservasis.created_at,
    emrkonservasis.updated_at,
    emrkonservasis.uploadrestorasibefore,
    emrkonservasis.uploadrestorasiafter,
    emrkonservasis.sblmperawatanfaktorrisikokaries_fluor_airminum,
    emrkonservasis.sblmperawatanfaktorrisikokaries_fluor_topikal,
    emrkonservasis.sblmperawatanfaktorrisikokaries_diet_asam,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_fluor_airminum,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_fluor_topikal,
    emrkonservasis.ssdhperawatanfaktorrisikokaries_diet_asam,
    emrkonservasis.status_emr,
    emrkonservasis.status_penilaian
   FROM public.emrkonservasis;


ALTER TABLE public.view_history_emrkonservasis OWNER TO rsyarsi;

--
-- TOC entry 263 (class 1259 OID 16653)
-- Name: view_history_emrortodonsies; Type: VIEW; Schema: public; Owner: rsyarsi
--

CREATE VIEW public.view_history_emrortodonsies AS
 SELECT emrortodonsies.id,
    emrortodonsies.noregister,
    emrortodonsies.noepisode,
    emrortodonsies.operator,
    emrortodonsies.nim,
    emrortodonsies.pembimbing,
    emrortodonsies.tanggal,
    emrortodonsies.namapasien,
    emrortodonsies.suku,
    emrortodonsies.umur,
    emrortodonsies.jeniskelamin,
    emrortodonsies.alamat,
    emrortodonsies.telepon,
    emrortodonsies.pekerjaan,
    emrortodonsies.rujukandari,
    emrortodonsies.namaayah,
    emrortodonsies.sukuayah,
    emrortodonsies.umurayah,
    emrortodonsies.namaibu,
    emrortodonsies.sukuibu,
    emrortodonsies.umuribu,
    emrortodonsies.pekerjaanorangtua,
    emrortodonsies.alamatorangtua,
    emrortodonsies.pendaftaran,
    emrortodonsies.pencetakan,
    emrortodonsies.pemasanganalat,
    emrortodonsies.waktuperawatan_retainer,
    emrortodonsies.keluhanutama,
    emrortodonsies.kelainanendoktrin,
    emrortodonsies.penyakitpadamasaanak,
    emrortodonsies.alergi,
    emrortodonsies.kelainansaluranpernapasan,
    emrortodonsies.tindakanoperasi,
    emrortodonsies.gigidesidui,
    emrortodonsies.gigibercampur,
    emrortodonsies.gigipermanen,
    emrortodonsies.durasi,
    emrortodonsies.frekuensi,
    emrortodonsies.intensitas,
    emrortodonsies.kebiasaanjelekketerangan,
    emrortodonsies.riwayatkeluarga,
    emrortodonsies.ayah,
    emrortodonsies.ibu,
    emrortodonsies.saudara,
    emrortodonsies.riwayatkeluargaketerangan,
    emrortodonsies.jasmani,
    emrortodonsies.mental,
    emrortodonsies.tinggibadan,
    emrortodonsies.beratbadan,
    emrortodonsies.indeksmassatubuh,
    emrortodonsies.statusgizi,
    emrortodonsies.kategori,
    emrortodonsies.lebarkepala,
    emrortodonsies.panjangkepala,
    emrortodonsies.indekskepala,
    emrortodonsies.bentukkepala,
    emrortodonsies.panjangmuka,
    emrortodonsies.lebarmuka,
    emrortodonsies.indeksmuka,
    emrortodonsies.bentukmuka,
    emrortodonsies.bentuk,
    emrortodonsies.profilmuka,
    emrortodonsies.senditemporomandibulat_tmj,
    emrortodonsies.tmj_keterangan,
    emrortodonsies.bibirposisiistirahat,
    emrortodonsies.tunusototmastikasi,
    emrortodonsies.tunusototmastikasi_keterangan,
    emrortodonsies.tunusototbibir,
    emrortodonsies.tunusototbibir_keterangan,
    emrortodonsies.freewayspace,
    emrortodonsies.pathofclosure,
    emrortodonsies.higienemulutohi,
    emrortodonsies.polaatrisi,
    emrortodonsies.regio,
    emrortodonsies.lingua,
    emrortodonsies.intraoral_lainlain,
    emrortodonsies.palatumvertikal,
    emrortodonsies.palatumlateral,
    emrortodonsies.gingiva,
    emrortodonsies.gingiva_keterangan,
    emrortodonsies.mukosa,
    emrortodonsies.mukosa_keterangan,
    emrortodonsies.frenlabiisuperior,
    emrortodonsies.frenlabiiinferior,
    emrortodonsies.frenlingualis,
    emrortodonsies.ketr,
    emrortodonsies.tonsila,
    emrortodonsies.fonetik,
    emrortodonsies.image_pemeriksaangigi,
    emrortodonsies.tampakdepantakterlihatgigi,
    emrortodonsies.fotomuka_bentukmuka,
    emrortodonsies.tampaksamping,
    emrortodonsies.fotomuka_profilmuka,
    emrortodonsies.tampakdepansenyumterlihatgigi,
    emrortodonsies.tampakmiring,
    emrortodonsies.tampaksampingkanan,
    emrortodonsies.tampakdepan,
    emrortodonsies.tampaksampingkiri,
    emrortodonsies.tampakoklusalatas,
    emrortodonsies.tampakoklusalbawah,
    emrortodonsies.bentuklengkunggigi_ra,
    emrortodonsies.bentuklengkunggigi_rb,
    emrortodonsies.malposisigigiindividual_rahangatas_kanan1,
    emrortodonsies.malposisigigiindividual_rahangatas_kanan2,
    emrortodonsies.malposisigigiindividual_rahangatas_kanan3,
    emrortodonsies.malposisigigiindividual_rahangatas_kanan4,
    emrortodonsies.malposisigigiindividual_rahangatas_kanan5,
    emrortodonsies.malposisigigiindividual_rahangatas_kanan6,
    emrortodonsies.malposisigigiindividual_rahangatas_kanan7,
    emrortodonsies.malposisigigiindividual_rahangatas_kiri1,
    emrortodonsies.malposisigigiindividual_rahangatas_kiri2,
    emrortodonsies.malposisigigiindividual_rahangatas_kiri3,
    emrortodonsies.malposisigigiindividual_rahangatas_kiri4,
    emrortodonsies.malposisigigiindividual_rahangatas_kiri5,
    emrortodonsies.malposisigigiindividual_rahangatas_kiri6,
    emrortodonsies.malposisigigiindividual_rahangatas_kiri7,
    emrortodonsies.malposisigigiindividual_rahangbawah_kanan1,
    emrortodonsies.malposisigigiindividual_rahangbawah_kanan2,
    emrortodonsies.malposisigigiindividual_rahangbawah_kanan3,
    emrortodonsies.malposisigigiindividual_rahangbawah_kanan4,
    emrortodonsies.malposisigigiindividual_rahangbawah_kanan5,
    emrortodonsies.malposisigigiindividual_rahangbawah_kanan6,
    emrortodonsies.malposisigigiindividual_rahangbawah_kanan7,
    emrortodonsies.malposisigigiindividual_rahangbawah_kiri1,
    emrortodonsies.malposisigigiindividual_rahangbawah_kiri2,
    emrortodonsies.malposisigigiindividual_rahangbawah_kiri3,
    emrortodonsies.malposisigigiindividual_rahangbawah_kiri4,
    emrortodonsies.malposisigigiindividual_rahangbawah_kiri5,
    emrortodonsies.malposisigigiindividual_rahangbawah_kiri6,
    emrortodonsies.malposisigigiindividual_rahangbawah_kiri7,
    emrortodonsies.overjet,
    emrortodonsies.overbite,
    emrortodonsies.palatalbite,
    emrortodonsies.deepbite,
    emrortodonsies.anterior_openbite,
    emrortodonsies.edgetobite,
    emrortodonsies.anterior_crossbite,
    emrortodonsies.posterior_openbite,
    emrortodonsies.scissorbite,
    emrortodonsies.cusptocuspbite,
    emrortodonsies.relasimolarpertamakanan,
    emrortodonsies.relasimolarpertamakiri,
    emrortodonsies.relasikaninuskanan,
    emrortodonsies.relasikaninuskiri,
    emrortodonsies.garistengahrahangbawahterhadaprahangatas,
    emrortodonsies.garisinterinsisivisentralterhadapgaristengahrahangra,
    emrortodonsies.garisinterinsisivisentralterhadapgaristengahrahangra_mm,
    emrortodonsies.garisinterinsisivisentralterhadapgaristengahrahangrb,
    emrortodonsies.garisinterinsisivisentralterhadapgaristengahrahangrb_mm,
    emrortodonsies.lebarmesiodistalgigi_rahangatas_kanan1,
    emrortodonsies.lebarmesiodistalgigi_rahangatas_kanan2,
    emrortodonsies.lebarmesiodistalgigi_rahangatas_kanan3,
    emrortodonsies.lebarmesiodistalgigi_rahangatas_kanan4,
    emrortodonsies.lebarmesiodistalgigi_rahangatas_kanan5,
    emrortodonsies.lebarmesiodistalgigi_rahangatas_kanan6,
    emrortodonsies.lebarmesiodistalgigi_rahangatas_kanan7,
    emrortodonsies.lebarmesiodistalgigi_rahangatas_kiri1,
    emrortodonsies.lebarmesiodistalgigi_rahangatas_kiri2,
    emrortodonsies.lebarmesiodistalgigi_rahangatas_kiri3,
    emrortodonsies.lebarmesiodistalgigi_rahangatas_kiri4,
    emrortodonsies.lebarmesiodistalgigi_rahangatas_kiri5,
    emrortodonsies.lebarmesiodistalgigi_rahangatas_kiri6,
    emrortodonsies.lebarmesiodistalgigi_rahangatas_kiri7,
    emrortodonsies.lebarmesiodistalgigi_rahangbawah_kanan1,
    emrortodonsies.lebarmesiodistalgigi_rahangbawah_kanan2,
    emrortodonsies.lebarmesiodistalgigi_rahangbawah_kanan3,
    emrortodonsies.lebarmesiodistalgigi_rahangbawah_kanan4,
    emrortodonsies.lebarmesiodistalgigi_rahangbawah_kanan5,
    emrortodonsies.lebarmesiodistalgigi_rahangbawah_kanan6,
    emrortodonsies.lebarmesiodistalgigi_rahangbawah_kanan7,
    emrortodonsies.lebarmesiodistalgigi_rahangbawah_kiri1,
    emrortodonsies.lebarmesiodistalgigi_rahangbawah_kiri2,
    emrortodonsies.lebarmesiodistalgigi_rahangbawah_kiri3,
    emrortodonsies.lebarmesiodistalgigi_rahangbawah_kiri4,
    emrortodonsies.lebarmesiodistalgigi_rahangbawah_kiri5,
    emrortodonsies.lebarmesiodistalgigi_rahangbawah_kiri6,
    emrortodonsies.lebarmesiodistalgigi_rahangbawah_kiri7,
    emrortodonsies.skemafotooklusalgigidarimodelstudi,
    emrortodonsies.jumlahmesiodistal,
    emrortodonsies.jarakp1p2pengukuran,
    emrortodonsies.jarakp1p2perhitungan,
    emrortodonsies.diskrepansip1p2_mm,
    emrortodonsies.diskrepansip1p2,
    emrortodonsies.jarakm1m1pengukuran,
    emrortodonsies.jarakm1m1perhitungan,
    emrortodonsies.diskrepansim1m2_mm,
    emrortodonsies.diskrepansim1m2,
    emrortodonsies.diskrepansi_keterangan,
    emrortodonsies.jumlahlebarmesiodistalgigidarim1m1,
    emrortodonsies.jarakp1p1tonjol,
    emrortodonsies.indeksp,
    emrortodonsies.lengkunggigiuntukmenampunggigigigi,
    emrortodonsies.jarakinterfossacaninus,
    emrortodonsies.indeksfc,
    emrortodonsies.lengkungbasaluntukmenampunggigigigi,
    emrortodonsies.inklinasigigigigiregioposterior,
    emrortodonsies.metodehowes_keterangan,
    emrortodonsies.aldmetode,
    emrortodonsies.overjetawal,
    emrortodonsies.overjetakhir,
    emrortodonsies.rahangatasdiskrepansi,
    emrortodonsies.rahangbawahdiskrepansi,
    emrortodonsies.fotosefalometri,
    emrortodonsies.fotopanoramik,
    emrortodonsies.maloklusiangleklas,
    emrortodonsies.hubunganskeletal,
    emrortodonsies.malrelasi,
    emrortodonsies.malposisi,
    emrortodonsies.estetik,
    emrortodonsies.dental,
    emrortodonsies.skeletal,
    emrortodonsies.fungsipenguyahanal,
    emrortodonsies.crowding,
    emrortodonsies.spacing,
    emrortodonsies.protrusif,
    emrortodonsies.retrusif,
    emrortodonsies.malposisiindividual,
    emrortodonsies.maloklusi_crossbite,
    emrortodonsies.maloklusi_lainlain,
    emrortodonsies.maloklusi_lainlainketerangan,
    emrortodonsies.rapencabutan,
    emrortodonsies.raekspansi,
    emrortodonsies.ragrinding,
    emrortodonsies.raplataktif,
    emrortodonsies.rbpencabutan,
    emrortodonsies.rbekspansi,
    emrortodonsies.rbgrinding,
    emrortodonsies.rbplataktif,
    emrortodonsies.analisisetiologimaloklusi,
    emrortodonsies.pasiendirujukkebagian,
    emrortodonsies.pencarianruanguntuk,
    emrortodonsies.koreksimalposisigigiindividual,
    emrortodonsies.retensi,
    emrortodonsies.pencarianruang,
    emrortodonsies.koreksimalposisigigiindividual_rahangatas,
    emrortodonsies.koreksimalposisigigiindividual_rahangbawah,
    emrortodonsies.intruksipadapasien,
    emrortodonsies.retainer,
    emrortodonsies.gambarplataktif_rahangatas,
    emrortodonsies.gambarplataktif_rahangbawah,
    emrortodonsies.keterangangambar,
    emrortodonsies.prognosis,
    emrortodonsies.prognosis_a,
    emrortodonsies.prognosis_b,
    emrortodonsies.prognosis_c,
    emrortodonsies.indikasiperawatan,
    emrortodonsies.created_at,
    emrortodonsies.updated_at,
    emrortodonsies.status_emr,
    emrortodonsies.status_penilaian
   FROM public.emrortodonsies;


ALTER TABLE public.view_history_emrortodonsies OWNER TO rsyarsi;

--
-- TOC entry 264 (class 1259 OID 16658)
-- Name: view_history_emrpedodonties; Type: VIEW; Schema: public; Owner: rsyarsi
--

CREATE VIEW public.view_history_emrpedodonties AS
 SELECT emrpedodonties.id,
    emrpedodonties.tanggalmasuk,
    emrpedodonties.nim,
    emrpedodonties.namamahasiswa,
    emrpedodonties.tahunklinik,
    emrpedodonties.namasupervisor,
    emrpedodonties.tandatangan,
    emrpedodonties.namapasien,
    emrpedodonties.jeniskelamin,
    emrpedodonties.alamatpasien,
    emrpedodonties.usiapasien,
    emrpedodonties.pendidikan,
    emrpedodonties.tgllahirpasien,
    emrpedodonties.namaorangtua,
    emrpedodonties.telephone,
    emrpedodonties.pekerjaan,
    emrpedodonties.dokteranak,
    emrpedodonties.alamatpekerjaan,
    emrpedodonties.telephonedranak,
    emrpedodonties.anamnesis,
    emrpedodonties.noregister,
    emrpedodonties.noepisode,
    emrpedodonties.physicalgrowth,
    emrpedodonties.heartdesease,
    emrpedodonties.created_at,
    emrpedodonties.updated_at,
    emrpedodonties.bruiseeasily,
    emrpedodonties.anemia,
    emrpedodonties.hepatitis,
    emrpedodonties.allergic,
    emrpedodonties.takinganymedicine,
    emrpedodonties.takinganymedicineobat,
    emrpedodonties.beenhospitalized,
    emrpedodonties.beenhospitalizedalasan,
    emrpedodonties.toothache,
    emrpedodonties.childtoothache,
    emrpedodonties.firstdental,
    emrpedodonties.unfavorabledentalexperience,
    emrpedodonties."where",
    emrpedodonties.reason,
    emrpedodonties.fingersucking,
    emrpedodonties.diffycultyopeningsjaw,
    emrpedodonties.howoftenbrushtooth,
    emrpedodonties.howoftenbrushtoothkali,
    emrpedodonties.usefluoridepasta,
    emrpedodonties.fluoridetreatmen,
    emrpedodonties.ifyes,
    emrpedodonties.bilateralsymmetry,
    emrpedodonties.asymmetry,
    emrpedodonties.straight,
    emrpedodonties.convex,
    emrpedodonties.concave,
    emrpedodonties.lipsseal,
    emrpedodonties.clicking,
    emrpedodonties.clickingleft,
    emrpedodonties.clickingright,
    emrpedodonties.pain,
    emrpedodonties.painleft,
    emrpedodonties.painright,
    emrpedodonties.bodypostur,
    emrpedodonties.gingivitis,
    emrpedodonties.stomatitis,
    emrpedodonties.dentalanomali,
    emrpedodonties.prematurloss,
    emrpedodonties.overretainedprimarytooth,
    emrpedodonties.odontogramfoto,
    emrpedodonties.gumboil,
    emrpedodonties.stageofdentition,
    emrpedodonties.franklscale_definitelynegative_before_treatment,
    emrpedodonties.franklscale_definitelynegative_during_treatment,
    emrpedodonties.franklscale_negative_before_treatment,
    emrpedodonties.franklscale_negative_during_treatment,
    emrpedodonties.franklscale_positive_before_treatment,
    emrpedodonties.franklscale_positive_during_treatment,
    emrpedodonties.franklscale_definitelypositive_before_treatment,
    emrpedodonties.franklscale_definitelypositive_during_treatment,
    emrpedodonties.buccal_18,
    emrpedodonties.buccal_17,
    emrpedodonties.buccal_16,
    emrpedodonties.buccal_15,
    emrpedodonties.buccal_14,
    emrpedodonties.buccal_13,
    emrpedodonties.buccal_12,
    emrpedodonties.buccal_11,
    emrpedodonties.buccal_21,
    emrpedodonties.buccal_22,
    emrpedodonties.buccal_23,
    emrpedodonties.buccal_24,
    emrpedodonties.buccal_25,
    emrpedodonties.buccal_26,
    emrpedodonties.buccal_27,
    emrpedodonties.buccal_28,
    emrpedodonties.palatal_55,
    emrpedodonties.palatal_54,
    emrpedodonties.palatal_53,
    emrpedodonties.palatal_52,
    emrpedodonties.palatal_51,
    emrpedodonties.palatal_61,
    emrpedodonties.palatal_62,
    emrpedodonties.palatal_63,
    emrpedodonties.palatal_64,
    emrpedodonties.palatal_65,
    emrpedodonties.buccal_85,
    emrpedodonties.buccal_84,
    emrpedodonties.buccal_83,
    emrpedodonties.buccal_82,
    emrpedodonties.buccal_81,
    emrpedodonties.buccal_71,
    emrpedodonties.buccal_72,
    emrpedodonties.buccal_73,
    emrpedodonties.buccal_74,
    emrpedodonties.buccal_75,
    emrpedodonties.palatal_48,
    emrpedodonties.palatal_47,
    emrpedodonties.palatal_46,
    emrpedodonties.palatal_45,
    emrpedodonties.palatal_44,
    emrpedodonties.palatal_43,
    emrpedodonties.palatal_42,
    emrpedodonties.palatal_41,
    emrpedodonties.palatal_31,
    emrpedodonties.palatal_32,
    emrpedodonties.palatal_33,
    emrpedodonties.palatal_34,
    emrpedodonties.palatal_35,
    emrpedodonties.palatal_36,
    emrpedodonties.palatal_37,
    emrpedodonties.palatal_38,
    emrpedodonties.dpalatal,
    emrpedodonties.epalatal,
    emrpedodonties.fpalatal,
    emrpedodonties.defpalatal,
    emrpedodonties.dlingual,
    emrpedodonties.elingual,
    emrpedodonties.flingual,
    emrpedodonties.deflingual,
    emrpedodonties.status_emr,
    emrpedodonties.status_penilaian
   FROM public.emrpedodonties;


ALTER TABLE public.view_history_emrpedodonties OWNER TO rsyarsi;

--
-- TOC entry 265 (class 1259 OID 16663)
-- Name: view_history_emrperiodonties; Type: VIEW; Schema: public; Owner: rsyarsi
--

CREATE VIEW public.view_history_emrperiodonties AS
 SELECT emrperiodonties.id,
    emrperiodonties.nama_mahasiswa,
    emrperiodonties.npm,
    emrperiodonties.tahun_klinik,
    emrperiodonties.opsi_imagemahasiswa,
    emrperiodonties.noregister,
    emrperiodonties.noepisode,
    emrperiodonties.no_rekammedik,
    emrperiodonties.kasus_pasien,
    emrperiodonties.tanggal_pemeriksaan,
    emrperiodonties.pendidikan_pasien,
    emrperiodonties.nama_pasien,
    emrperiodonties.umur_pasien,
    emrperiodonties.jenis_kelamin_pasien,
    emrperiodonties.alamat,
    emrperiodonties.no_telephone_pasien,
    emrperiodonties.pemeriksa,
    emrperiodonties.operator1,
    emrperiodonties.operator2,
    emrperiodonties.operator3,
    emrperiodonties.operator4,
    emrperiodonties.konsuldari,
    emrperiodonties.keluhanutama,
    emrperiodonties.anamnesis,
    emrperiodonties.gusi_mudah_berdarah,
    emrperiodonties.gusi_mudah_berdarah_lainlain,
    emrperiodonties.penyakit_sistemik,
    emrperiodonties.penyakit_sistemik_bilaada,
    emrperiodonties.penyakit_sistemik_obat,
    emrperiodonties.diabetes_melitus,
    emrperiodonties.diabetes_melituskadargula,
    emrperiodonties.merokok,
    emrperiodonties.merokok_perhari,
    emrperiodonties.merokok_tahun_awal,
    emrperiodonties.merokok_tahun_akhir,
    emrperiodonties.gigi_pernah_tanggal_dalam_keadaan_baik,
    emrperiodonties.keadaan_umum,
    emrperiodonties.tekanan_darah,
    emrperiodonties.extra_oral,
    emrperiodonties.intra_oral,
    emrperiodonties.oral_hygiene_bop,
    emrperiodonties.oral_hygiene_ci,
    emrperiodonties.oral_hygiene_pi,
    emrperiodonties.oral_hygiene_ohis,
    emrperiodonties.kesimpulan_ohis,
    emrperiodonties.rakn_keaadan_gingiva,
    emrperiodonties.rakn_karang_gigi,
    emrperiodonties.rakn_oklusi,
    emrperiodonties.rakn_artikulasi,
    emrperiodonties.rakn_abrasi_atrisi_abfraksi,
    emrperiodonties.ram_keaadan_gingiva,
    emrperiodonties.ram_karang_gigi,
    emrperiodonties.ram_oklusi,
    emrperiodonties.ram_artikulasi,
    emrperiodonties.ram_abrasi_atrisi_abfraksi,
    emrperiodonties.rakr_keaadan_gingiva,
    emrperiodonties.rakr_karang_gigi,
    emrperiodonties.rakr_oklusi,
    emrperiodonties.rakr_artikulasi,
    emrperiodonties.rakr_abrasi_atrisi_abfraksi,
    emrperiodonties.rbkn_keaadan_gingiva,
    emrperiodonties.rbkn_karang_gigi,
    emrperiodonties.rbkn_oklusi,
    emrperiodonties.rbkn_artikulasi,
    emrperiodonties.rbkn_abrasi_atrisi_abfraksi,
    emrperiodonties.rbm_keaadan_gingiva,
    emrperiodonties.rbm_karang_gigi,
    emrperiodonties.rbm_oklusi,
    emrperiodonties.rbm_artikulasi,
    emrperiodonties.rbm_abrasi_atrisi_abfraksi,
    emrperiodonties.rbkr_keaadan_gingiva,
    emrperiodonties.rbkr_karang_gigi,
    emrperiodonties.rbkr_oklusi,
    emrperiodonties.rbkr_artikulasi,
    emrperiodonties.rbkr_abrasi_atrisi_abfraksi,
    emrperiodonties.rakn_1_v,
    emrperiodonties.rakn_1_g,
    emrperiodonties.rakn_1_pm,
    emrperiodonties.rakn_1_pb,
    emrperiodonties.rakn_1_pd,
    emrperiodonties.rakn_1_pp,
    emrperiodonties.rakn_1_o,
    emrperiodonties.rakn_1_r,
    emrperiodonties.rakn_1_la,
    emrperiodonties.rakn_1_mp,
    emrperiodonties.rakn_1_bop,
    emrperiodonties.rakn_1_tk,
    emrperiodonties.rakn_1_fi,
    emrperiodonties.rakn_1_k,
    emrperiodonties.rakn_1_t,
    emrperiodonties.rakn_2_v,
    emrperiodonties.rakn_2_g,
    emrperiodonties.rakn_2_pm,
    emrperiodonties.rakn_2_pb,
    emrperiodonties.rakn_2_pd,
    emrperiodonties.rakn_2_pp,
    emrperiodonties.rakn_2_o,
    emrperiodonties.rakn_2_r,
    emrperiodonties.rakn_2_la,
    emrperiodonties.rakn_2_mp,
    emrperiodonties.rakn_2_bop,
    emrperiodonties.rakn_2_tk,
    emrperiodonties.rakn_2_fi,
    emrperiodonties.rakn_2_k,
    emrperiodonties.rakn_2_t,
    emrperiodonties.rakn_3_v,
    emrperiodonties.rakn_3_g,
    emrperiodonties.rakn_3_pm,
    emrperiodonties.rakn_3_pb,
    emrperiodonties.rakn_3_pd,
    emrperiodonties.rakn_3_pp,
    emrperiodonties.rakn_3_o,
    emrperiodonties.rakn_3_r,
    emrperiodonties.rakn_3_la,
    emrperiodonties.rakn_3_mp,
    emrperiodonties.rakn_3_bop,
    emrperiodonties.rakn_3_tk,
    emrperiodonties.rakn_3_fi,
    emrperiodonties.rakn_3_k,
    emrperiodonties.rakn_3_t,
    emrperiodonties.rakn_4_v,
    emrperiodonties.rakn_4_g,
    emrperiodonties.rakn_4_pm,
    emrperiodonties.rakn_4_pb,
    emrperiodonties.rakn_4_pd,
    emrperiodonties.rakn_4_pp,
    emrperiodonties.rakn_4_o,
    emrperiodonties.rakn_4_r,
    emrperiodonties.rakn_4_la,
    emrperiodonties.rakn_4_mp,
    emrperiodonties.rakn_4_bop,
    emrperiodonties.rakn_4_tk,
    emrperiodonties.rakn_4_fi,
    emrperiodonties.rakn_4_k,
    emrperiodonties.rakn_4_t,
    emrperiodonties.rakn_5_v,
    emrperiodonties.rakn_5_g,
    emrperiodonties.rakn_5_pm,
    emrperiodonties.rakn_5_pb,
    emrperiodonties.rakn_5_pd,
    emrperiodonties.rakn_5_pp,
    emrperiodonties.rakn_5_o,
    emrperiodonties.rakn_5_r,
    emrperiodonties.rakn_5_la,
    emrperiodonties.rakn_5_mp,
    emrperiodonties.rakn_5_bop,
    emrperiodonties.rakn_5_tk,
    emrperiodonties.rakn_5_fi,
    emrperiodonties.rakn_5_k,
    emrperiodonties.rakn_5_t,
    emrperiodonties.rakn_6_v,
    emrperiodonties.rakn_6_g,
    emrperiodonties.rakn_6_pm,
    emrperiodonties.rakn_6_pb,
    emrperiodonties.rakn_6_pd,
    emrperiodonties.rakn_6_pp,
    emrperiodonties.rakn_6_o,
    emrperiodonties.rakn_6_r,
    emrperiodonties.rakn_6_la,
    emrperiodonties.rakn_6_mp,
    emrperiodonties.rakn_6_bop,
    emrperiodonties.rakn_6_tk,
    emrperiodonties.rakn_6_fi,
    emrperiodonties.rakn_6_k,
    emrperiodonties.rakn_6_t,
    emrperiodonties.rakn_7_v,
    emrperiodonties.rakn_7_g,
    emrperiodonties.rakn_7_pm,
    emrperiodonties.rakn_7_pb,
    emrperiodonties.rakn_7_pd,
    emrperiodonties.rakn_7_pp,
    emrperiodonties.rakn_7_o,
    emrperiodonties.rakn_7_r,
    emrperiodonties.rakn_7_la,
    emrperiodonties.rakn_7_mp,
    emrperiodonties.rakn_7_bop,
    emrperiodonties.rakn_7_tk,
    emrperiodonties.rakn_7_fi,
    emrperiodonties.rakn_7_k,
    emrperiodonties.rakn_7_t,
    emrperiodonties.rakn_8_v,
    emrperiodonties.rakn_8_g,
    emrperiodonties.rakn_8_pm,
    emrperiodonties.rakn_8_pb,
    emrperiodonties.rakn_8_pd,
    emrperiodonties.rakn_8_pp,
    emrperiodonties.rakn_8_o,
    emrperiodonties.rakn_8_r,
    emrperiodonties.rakn_8_la,
    emrperiodonties.rakn_8_mp,
    emrperiodonties.rakn_8_bop,
    emrperiodonties.rakn_8_tk,
    emrperiodonties.rakn_8_fi,
    emrperiodonties.rakn_8_k,
    emrperiodonties.rakn_8_t,
    emrperiodonties.rakr_1_v,
    emrperiodonties.rakr_1_g,
    emrperiodonties.rakr_1_pm,
    emrperiodonties.rakr_1_pb,
    emrperiodonties.rakr_1_pd,
    emrperiodonties.rakr_1_pp,
    emrperiodonties.rakr_1_o,
    emrperiodonties.rakr_1_r,
    emrperiodonties.rakr_1_la,
    emrperiodonties.rakr_1_mp,
    emrperiodonties.rakr_1_bop,
    emrperiodonties.rakr_1_tk,
    emrperiodonties.rakr_1_fi,
    emrperiodonties.rakr_1_k,
    emrperiodonties.rakr_1_t,
    emrperiodonties.rakr_2_v,
    emrperiodonties.rakr_2_g,
    emrperiodonties.rakr_2_pm,
    emrperiodonties.rakr_2_pb,
    emrperiodonties.rakr_2_pd,
    emrperiodonties.rakr_2_pp,
    emrperiodonties.rakr_2_o,
    emrperiodonties.rakr_2_r,
    emrperiodonties.rakr_2_la,
    emrperiodonties.rakr_2_mp,
    emrperiodonties.rakr_2_bop,
    emrperiodonties.rakr_2_tk,
    emrperiodonties.rakr_2_fi,
    emrperiodonties.rakr_2_k,
    emrperiodonties.rakr_2_t,
    emrperiodonties.rakr_3_v,
    emrperiodonties.rakr_3_g,
    emrperiodonties.rakr_3_pm,
    emrperiodonties.rakr_3_pb,
    emrperiodonties.rakr_3_pd,
    emrperiodonties.rakr_3_pp,
    emrperiodonties.rakr_3_o,
    emrperiodonties.rakr_3_r,
    emrperiodonties.rakr_3_la,
    emrperiodonties.rakr_3_mp,
    emrperiodonties.rakr_3_bop,
    emrperiodonties.rakr_3_tk,
    emrperiodonties.rakr_3_fi,
    emrperiodonties.rakr_3_k,
    emrperiodonties.rakr_3_t,
    emrperiodonties.rakr_4_v,
    emrperiodonties.rakr_4_g,
    emrperiodonties.rakr_4_pm,
    emrperiodonties.rakr_4_pb,
    emrperiodonties.rakr_4_pd,
    emrperiodonties.rakr_4_pp,
    emrperiodonties.rakr_4_o,
    emrperiodonties.rakr_4_r,
    emrperiodonties.rakr_4_la,
    emrperiodonties.rakr_4_mp,
    emrperiodonties.rakr_4_bop,
    emrperiodonties.rakr_4_tk,
    emrperiodonties.rakr_4_fi,
    emrperiodonties.rakr_4_k,
    emrperiodonties.rakr_4_t,
    emrperiodonties.rakr_5_v,
    emrperiodonties.rakr_5_g,
    emrperiodonties.rakr_5_pm,
    emrperiodonties.rakr_5_pb,
    emrperiodonties.rakr_5_pd,
    emrperiodonties.rakr_5_pp,
    emrperiodonties.rakr_5_o,
    emrperiodonties.rakr_5_r,
    emrperiodonties.rakr_5_la,
    emrperiodonties.rakr_5_mp,
    emrperiodonties.rakr_5_bop,
    emrperiodonties.rakr_5_tk,
    emrperiodonties.rakr_5_fi,
    emrperiodonties.rakr_5_k,
    emrperiodonties.rakr_5_t,
    emrperiodonties.rakr_6_v,
    emrperiodonties.rakr_6_g,
    emrperiodonties.rakr_6_pm,
    emrperiodonties.rakr_6_pb,
    emrperiodonties.rakr_6_pd,
    emrperiodonties.rakr_6_pp,
    emrperiodonties.rakr_6_o,
    emrperiodonties.rakr_6_r,
    emrperiodonties.rakr_6_la,
    emrperiodonties.rakr_6_mp,
    emrperiodonties.rakr_6_bop,
    emrperiodonties.rakr_6_tk,
    emrperiodonties.rakr_6_fi,
    emrperiodonties.rakr_6_k,
    emrperiodonties.rakr_6_t,
    emrperiodonties.rakr_7_v,
    emrperiodonties.rakr_7_g,
    emrperiodonties.rakr_7_pm,
    emrperiodonties.rakr_7_pb,
    emrperiodonties.rakr_7_pd,
    emrperiodonties.rakr_7_pp,
    emrperiodonties.rakr_7_o,
    emrperiodonties.rakr_7_r,
    emrperiodonties.rakr_7_la,
    emrperiodonties.rakr_7_mp,
    emrperiodonties.rakr_7_bop,
    emrperiodonties.rakr_7_tk,
    emrperiodonties.rakr_7_fi,
    emrperiodonties.rakr_7_k,
    emrperiodonties.rakr_7_t,
    emrperiodonties.rakr_8_v,
    emrperiodonties.rakr_8_g,
    emrperiodonties.rakr_8_pm,
    emrperiodonties.rakr_8_pb,
    emrperiodonties.rakr_8_pd,
    emrperiodonties.rakr_8_pp,
    emrperiodonties.rakr_8_o,
    emrperiodonties.rakr_8_r,
    emrperiodonties.rakr_8_la,
    emrperiodonties.rakr_8_mp,
    emrperiodonties.rakr_8_bop,
    emrperiodonties.rakr_8_tk,
    emrperiodonties.rakr_8_fi,
    emrperiodonties.rakr_8_k,
    emrperiodonties.rakr_8_t,
    emrperiodonties.rbkn_1_v,
    emrperiodonties.rbkn_1_g,
    emrperiodonties.rbkn_1_pm,
    emrperiodonties.rbkn_1_pb,
    emrperiodonties.rbkn_1_pd,
    emrperiodonties.rbkn_1_pp,
    emrperiodonties.rbkn_1_o,
    emrperiodonties.rbkn_1_r,
    emrperiodonties.rbkn_1_la,
    emrperiodonties.rbkn_1_mp,
    emrperiodonties.rbkn_1_bop,
    emrperiodonties.rbkn_1_tk,
    emrperiodonties.rbkn_1_fi,
    emrperiodonties.rbkn_1_k,
    emrperiodonties.rbkn_1_t,
    emrperiodonties.rbkn_2_v,
    emrperiodonties.rbkn_2_g,
    emrperiodonties.rbkn_2_pm,
    emrperiodonties.rbkn_2_pb,
    emrperiodonties.rbkn_2_pd,
    emrperiodonties.rbkn_2_pp,
    emrperiodonties.rbkn_2_o,
    emrperiodonties.rbkn_2_r,
    emrperiodonties.rbkn_2_la,
    emrperiodonties.rbkn_2_mp,
    emrperiodonties.rbkn_2_bop,
    emrperiodonties.rbkn_2_tk,
    emrperiodonties.rbkn_2_fi,
    emrperiodonties.rbkn_2_k,
    emrperiodonties.rbkn_2_t,
    emrperiodonties.rbkn_3_v,
    emrperiodonties.rbkn_3_g,
    emrperiodonties.rbkn_3_pm,
    emrperiodonties.rbkn_3_pb,
    emrperiodonties.rbkn_3_pd,
    emrperiodonties.rbkn_3_pp,
    emrperiodonties.rbkn_3_o,
    emrperiodonties.rbkn_3_r,
    emrperiodonties.rbkn_3_la,
    emrperiodonties.rbkn_3_mp,
    emrperiodonties.rbkn_3_bop,
    emrperiodonties.rbkn_3_tk,
    emrperiodonties.rbkn_3_fi,
    emrperiodonties.rbkn_3_k,
    emrperiodonties.rbkn_3_t,
    emrperiodonties.rbkn_4_v,
    emrperiodonties.rbkn_4_g,
    emrperiodonties.rbkn_4_pm,
    emrperiodonties.rbkn_4_pb,
    emrperiodonties.rbkn_4_pd,
    emrperiodonties.rbkn_4_pp,
    emrperiodonties.rbkn_4_o,
    emrperiodonties.rbkn_4_r,
    emrperiodonties.rbkn_4_la,
    emrperiodonties.rbkn_4_mp,
    emrperiodonties.rbkn_4_bop,
    emrperiodonties.rbkn_4_tk,
    emrperiodonties.rbkn_4_fi,
    emrperiodonties.rbkn_4_k,
    emrperiodonties.rbkn_4_t,
    emrperiodonties.rbkn_5_v,
    emrperiodonties.rbkn_5_g,
    emrperiodonties.rbkn_5_pm,
    emrperiodonties.rbkn_5_pb,
    emrperiodonties.rbkn_5_pd,
    emrperiodonties.rbkn_5_pp,
    emrperiodonties.rbkn_5_o,
    emrperiodonties.rbkn_5_r,
    emrperiodonties.rbkn_5_la,
    emrperiodonties.rbkn_5_mp,
    emrperiodonties.rbkn_5_bop,
    emrperiodonties.rbkn_5_tk,
    emrperiodonties.rbkn_5_fi,
    emrperiodonties.rbkn_5_k,
    emrperiodonties.rbkn_5_t,
    emrperiodonties.rbkn_6_v,
    emrperiodonties.rbkn_6_g,
    emrperiodonties.rbkn_6_pm,
    emrperiodonties.rbkn_6_pb,
    emrperiodonties.rbkn_6_pd,
    emrperiodonties.rbkn_6_pp,
    emrperiodonties.rbkn_6_o,
    emrperiodonties.rbkn_6_r,
    emrperiodonties.rbkn_6_la,
    emrperiodonties.rbkn_6_mp,
    emrperiodonties.rbkn_6_bop,
    emrperiodonties.rbkn_6_tk,
    emrperiodonties.rbkn_6_fi,
    emrperiodonties.rbkn_6_k,
    emrperiodonties.rbkn_6_t,
    emrperiodonties.rbkn_7_v,
    emrperiodonties.rbkn_7_g,
    emrperiodonties.rbkn_7_pm,
    emrperiodonties.rbkn_7_pb,
    emrperiodonties.rbkn_7_pd,
    emrperiodonties.rbkn_7_pp,
    emrperiodonties.rbkn_7_o,
    emrperiodonties.rbkn_7_r,
    emrperiodonties.rbkn_7_la,
    emrperiodonties.rbkn_7_mp,
    emrperiodonties.rbkn_7_bop,
    emrperiodonties.rbkn_7_tk,
    emrperiodonties.rbkn_7_fi,
    emrperiodonties.rbkn_7_k,
    emrperiodonties.rbkn_7_t,
    emrperiodonties.rbkn_8_v,
    emrperiodonties.rbkn_8_g,
    emrperiodonties.rbkn_8_pm,
    emrperiodonties.rbkn_8_pb,
    emrperiodonties.rbkn_8_pd,
    emrperiodonties.rbkn_8_pp,
    emrperiodonties.rbkn_8_o,
    emrperiodonties.rbkn_8_r,
    emrperiodonties.rbkn_8_la,
    emrperiodonties.rbkn_8_mp,
    emrperiodonties.rbkn_8_bop,
    emrperiodonties.rbkn_8_tk,
    emrperiodonties.rbkn_8_fi,
    emrperiodonties.rbkn_8_k,
    emrperiodonties.rbkn_8_t,
    emrperiodonties.rbkr_1_v,
    emrperiodonties.rbkr_1_g,
    emrperiodonties.rbkr_1_pm,
    emrperiodonties.rbkr_1_pb,
    emrperiodonties.rbkr_1_pd,
    emrperiodonties.rbkr_1_pp,
    emrperiodonties.rbkr_1_o,
    emrperiodonties.rbkr_1_r,
    emrperiodonties.rbkr_1_la,
    emrperiodonties.rbkr_1_mp,
    emrperiodonties.rbkr_1_bop,
    emrperiodonties.rbkr_1_tk,
    emrperiodonties.rbkr_1_fi,
    emrperiodonties.rbkr_1_k,
    emrperiodonties.rbkr_1_t,
    emrperiodonties.rbkr_2_v,
    emrperiodonties.rbkr_2_g,
    emrperiodonties.rbkr_2_pm,
    emrperiodonties.rbkr_2_pb,
    emrperiodonties.rbkr_2_pd,
    emrperiodonties.rbkr_2_pp,
    emrperiodonties.rbkr_2_o,
    emrperiodonties.rbkr_2_r,
    emrperiodonties.rbkr_2_la,
    emrperiodonties.rbkr_2_mp,
    emrperiodonties.rbkr_2_bop,
    emrperiodonties.rbkr_2_tk,
    emrperiodonties.rbkr_2_fi,
    emrperiodonties.rbkr_2_k,
    emrperiodonties.rbkr_2_t,
    emrperiodonties.rbkr_3_v,
    emrperiodonties.rbkr_3_g,
    emrperiodonties.rbkr_3_pm,
    emrperiodonties.rbkr_3_pb,
    emrperiodonties.rbkr_3_pd,
    emrperiodonties.rbkr_3_pp,
    emrperiodonties.rbkr_3_o,
    emrperiodonties.rbkr_3_r,
    emrperiodonties.rbkr_3_la,
    emrperiodonties.rbkr_3_mp,
    emrperiodonties.rbkr_3_bop,
    emrperiodonties.rbkr_3_tk,
    emrperiodonties.rbkr_3_fi,
    emrperiodonties.rbkr_3_k,
    emrperiodonties.rbkr_3_t,
    emrperiodonties.rbkr_4_v,
    emrperiodonties.rbkr_4_g,
    emrperiodonties.rbkr_4_pm,
    emrperiodonties.rbkr_4_pb,
    emrperiodonties.rbkr_4_pd,
    emrperiodonties.rbkr_4_pp,
    emrperiodonties.rbkr_4_o,
    emrperiodonties.rbkr_4_r,
    emrperiodonties.rbkr_4_la,
    emrperiodonties.rbkr_4_mp,
    emrperiodonties.rbkr_4_bop,
    emrperiodonties.rbkr_4_tk,
    emrperiodonties.rbkr_4_fi,
    emrperiodonties.rbkr_4_k,
    emrperiodonties.rbkr_4_t,
    emrperiodonties.rbkr_5_v,
    emrperiodonties.rbkr_5_g,
    emrperiodonties.rbkr_5_pm,
    emrperiodonties.rbkr_5_pb,
    emrperiodonties.rbkr_5_pd,
    emrperiodonties.rbkr_5_pp,
    emrperiodonties.rbkr_5_o,
    emrperiodonties.rbkr_5_r,
    emrperiodonties.rbkr_5_la,
    emrperiodonties.rbkr_5_mp,
    emrperiodonties.rbkr_5_bop,
    emrperiodonties.rbkr_5_tk,
    emrperiodonties.rbkr_5_fi,
    emrperiodonties.rbkr_5_k,
    emrperiodonties.rbkr_5_t,
    emrperiodonties.rbkr_6_v,
    emrperiodonties.rbkr_6_g,
    emrperiodonties.rbkr_6_pm,
    emrperiodonties.rbkr_6_pb,
    emrperiodonties.rbkr_6_pd,
    emrperiodonties.rbkr_6_pp,
    emrperiodonties.rbkr_6_o,
    emrperiodonties.rbkr_6_r,
    emrperiodonties.rbkr_6_la,
    emrperiodonties.rbkr_6_mp,
    emrperiodonties.rbkr_6_bop,
    emrperiodonties.rbkr_6_tk,
    emrperiodonties.rbkr_6_fi,
    emrperiodonties.rbkr_6_k,
    emrperiodonties.rbkr_6_t,
    emrperiodonties.rbkr_7_v,
    emrperiodonties.rbkr_7_g,
    emrperiodonties.rbkr_7_pm,
    emrperiodonties.rbkr_7_pb,
    emrperiodonties.rbkr_7_pd,
    emrperiodonties.rbkr_7_pp,
    emrperiodonties.rbkr_7_o,
    emrperiodonties.rbkr_7_r,
    emrperiodonties.rbkr_7_la,
    emrperiodonties.rbkr_7_mp,
    emrperiodonties.rbkr_7_bop,
    emrperiodonties.rbkr_7_tk,
    emrperiodonties.rbkr_7_fi,
    emrperiodonties.rbkr_7_k,
    emrperiodonties.rbkr_7_t,
    emrperiodonties.rbkr_8_v,
    emrperiodonties.rbkr_8_g,
    emrperiodonties.rbkr_8_pm,
    emrperiodonties.rbkr_8_pb,
    emrperiodonties.rbkr_8_pd,
    emrperiodonties.rbkr_8_pp,
    emrperiodonties.rbkr_8_o,
    emrperiodonties.rbkr_8_r,
    emrperiodonties.rbkr_8_la,
    emrperiodonties.rbkr_8_mp,
    emrperiodonties.rbkr_8_bop,
    emrperiodonties.rbkr_8_tk,
    emrperiodonties.rbkr_8_fi,
    emrperiodonties.rbkr_8_k,
    emrperiodonties.rbkr_8_t,
    emrperiodonties.diagnosis_klinik,
    emrperiodonties.gambaran_radiografis,
    emrperiodonties.indikasi,
    emrperiodonties.terapi,
    emrperiodonties.keterangan,
    emrperiodonties.prognosis_umum,
    emrperiodonties.prognosis_lokal,
    emrperiodonties.p1_tanggal,
    emrperiodonties.p1_indeksplak_ra_el16_b,
    emrperiodonties.p1_indeksplak_ra_el12_b,
    emrperiodonties.p1_indeksplak_ra_el11_b,
    emrperiodonties.p1_indeksplak_ra_el21_b,
    emrperiodonties.p1_indeksplak_ra_el22_b,
    emrperiodonties.p1_indeksplak_ra_el24_b,
    emrperiodonties.p1_indeksplak_ra_el26_b,
    emrperiodonties.p1_indeksplak_ra_el16_l,
    emrperiodonties.p1_indeksplak_ra_el12_l,
    emrperiodonties.p1_indeksplak_ra_el11_l,
    emrperiodonties.p1_indeksplak_ra_el21_l,
    emrperiodonties.p1_indeksplak_ra_el22_l,
    emrperiodonties.p1_indeksplak_ra_el24_l,
    emrperiodonties.p1_indeksplak_ra_el26_l,
    emrperiodonties.p1_indeksplak_rb_el36_b,
    emrperiodonties.p1_indeksplak_rb_el34_b,
    emrperiodonties.p1_indeksplak_rb_el32_b,
    emrperiodonties.p1_indeksplak_rb_el31_b,
    emrperiodonties.p1_indeksplak_rb_el41_b,
    emrperiodonties.p1_indeksplak_rb_el42_b,
    emrperiodonties.p1_indeksplak_rb_el46_b,
    emrperiodonties.p1_indeksplak_rb_el36_l,
    emrperiodonties.p1_indeksplak_rb_el34_l,
    emrperiodonties.p1_indeksplak_rb_el32_l,
    emrperiodonties.p1_indeksplak_rb_el31_l,
    emrperiodonties.p1_indeksplak_rb_el41_l,
    emrperiodonties.p1_indeksplak_rb_el42_l,
    emrperiodonties.p1_indeksplak_rb_el46_l,
    emrperiodonties.p1_bop_ra_el16_b,
    emrperiodonties.p1_bop_ra_el12_b,
    emrperiodonties.p1_bop_ra_el11_b,
    emrperiodonties.p1_bop_ra_el21_b,
    emrperiodonties.p1_bop_ra_el22_b,
    emrperiodonties.p1_bop_ra_el24_b,
    emrperiodonties.p1_bop_ra_el26_b,
    emrperiodonties.p1_bop_ra_el16_l,
    emrperiodonties.p1_bop_ra_el12_l,
    emrperiodonties.p1_bop_ra_el11_l,
    emrperiodonties.p1_bop_ra_el21_l,
    emrperiodonties.p1_bop_ra_el22_l,
    emrperiodonties.p1_bop_ra_el24_l,
    emrperiodonties.p1_bop_ra_el26_l,
    emrperiodonties.p1_bop_rb_el36_b,
    emrperiodonties.p1_bop_rb_el34_b,
    emrperiodonties.p1_bop_rb_el32_b,
    emrperiodonties.p1_bop_rb_el31_b,
    emrperiodonties.p1_bop_rb_el41_b,
    emrperiodonties.p1_bop_rb_el42_b,
    emrperiodonties.p1_bop_rb_el46_b,
    emrperiodonties.p1_bop_rb_el36_l,
    emrperiodonties.p1_bop_rb_el34_l,
    emrperiodonties.p1_bop_rb_el32_l,
    emrperiodonties.p1_bop_rb_el31_l,
    emrperiodonties.p1_bop_rb_el41_l,
    emrperiodonties.p1_bop_rb_el42_l,
    emrperiodonties.p1_bop_rb_el46_l,
    emrperiodonties.p1_indekskalkulus_ra_el16_b,
    emrperiodonties.p1_indekskalkulus_ra_el26_b,
    emrperiodonties.p1_indekskalkulus_ra_el16_l,
    emrperiodonties.p1_indekskalkulus_ra_el26_l,
    emrperiodonties.p1_indekskalkulus_rb_el36_b,
    emrperiodonties.p1_indekskalkulus_rb_el34_b,
    emrperiodonties.p1_indekskalkulus_rb_el32_b,
    emrperiodonties.p1_indekskalkulus_rb_el31_b,
    emrperiodonties.p1_indekskalkulus_rb_el41_b,
    emrperiodonties.p1_indekskalkulus_rb_el42_b,
    emrperiodonties.p1_indekskalkulus_rb_el46_b,
    emrperiodonties.p1_indekskalkulus_rb_el36_l,
    emrperiodonties.p1_indekskalkulus_rb_el34_l,
    emrperiodonties.p1_indekskalkulus_rb_el32_l,
    emrperiodonties.p1_indekskalkulus_rb_el31_l,
    emrperiodonties.p1_indekskalkulus_rb_el41_l,
    emrperiodonties.p1_indekskalkulus_rb_el42_l,
    emrperiodonties.p1_indekskalkulus_rb_el46_l,
    emrperiodonties.p2_tanggal,
    emrperiodonties.p2_indeksplak_ra_el16_b,
    emrperiodonties.p2_indeksplak_ra_el12_b,
    emrperiodonties.p2_indeksplak_ra_el11_b,
    emrperiodonties.p2_indeksplak_ra_el21_b,
    emrperiodonties.p2_indeksplak_ra_el22_b,
    emrperiodonties.p2_indeksplak_ra_el24_b,
    emrperiodonties.p2_indeksplak_ra_el26_b,
    emrperiodonties.p2_indeksplak_ra_el16_l,
    emrperiodonties.p2_indeksplak_ra_el12_l,
    emrperiodonties.p2_indeksplak_ra_el11_l,
    emrperiodonties.p2_indeksplak_ra_el21_l,
    emrperiodonties.p2_indeksplak_ra_el22_l,
    emrperiodonties.p2_indeksplak_ra_el24_l,
    emrperiodonties.p2_indeksplak_ra_el26_l,
    emrperiodonties.p2_indeksplak_rb_el36_b,
    emrperiodonties.p2_indeksplak_rb_el34_b,
    emrperiodonties.p2_indeksplak_rb_el32_b,
    emrperiodonties.p2_indeksplak_rb_el31_b,
    emrperiodonties.p2_indeksplak_rb_el41_b,
    emrperiodonties.p2_indeksplak_rb_el42_b,
    emrperiodonties.p2_indeksplak_rb_el46_b,
    emrperiodonties.p2_indeksplak_rb_el36_l,
    emrperiodonties.p2_indeksplak_rb_el34_l,
    emrperiodonties.p2_indeksplak_rb_el32_l,
    emrperiodonties.p2_indeksplak_rb_el31_l,
    emrperiodonties.p2_indeksplak_rb_el41_l,
    emrperiodonties.p2_indeksplak_rb_el42_l,
    emrperiodonties.p2_indeksplak_rb_el46_l,
    emrperiodonties.p2_bop_ra_el16_b,
    emrperiodonties.p2_bop_ra_el12_b,
    emrperiodonties.p2_bop_ra_el11_b,
    emrperiodonties.p2_bop_ra_el21_b,
    emrperiodonties.p2_bop_ra_el22_b,
    emrperiodonties.p2_bop_ra_el24_b,
    emrperiodonties.p2_bop_ra_el26_b,
    emrperiodonties.p2_bop_ra_el16_l,
    emrperiodonties.p2_bop_ra_el12_l,
    emrperiodonties.p2_bop_ra_el11_l,
    emrperiodonties.p2_bop_ra_el21_l,
    emrperiodonties.p2_bop_ra_el22_l,
    emrperiodonties.p2_bop_ra_el24_l,
    emrperiodonties.p2_bop_ra_el26_l,
    emrperiodonties.p2_bop_rb_el36_b,
    emrperiodonties.p2_bop_rb_el34_b,
    emrperiodonties.p2_bop_rb_el32_b,
    emrperiodonties.p2_bop_rb_el31_b,
    emrperiodonties.p2_bop_rb_el41_b,
    emrperiodonties.p2_bop_rb_el42_b,
    emrperiodonties.p2_bop_rb_el46_b,
    emrperiodonties.p2_bop_rb_el36_l,
    emrperiodonties.p2_bop_rb_el34_l,
    emrperiodonties.p2_bop_rb_el32_l,
    emrperiodonties.p2_bop_rb_el31_l,
    emrperiodonties.p2_bop_rb_el41_l,
    emrperiodonties.p2_bop_rb_el42_l,
    emrperiodonties.p2_bop_rb_el46_l,
    emrperiodonties.p2_indekskalkulus_ra_el16_b,
    emrperiodonties.p2_indekskalkulus_ra_el26_b,
    emrperiodonties.p2_indekskalkulus_ra_el16_l,
    emrperiodonties.p2_indekskalkulus_ra_el26_l,
    emrperiodonties.p2_indekskalkulus_rb_el36_b,
    emrperiodonties.p2_indekskalkulus_rb_el34_b,
    emrperiodonties.p2_indekskalkulus_rb_el32_b,
    emrperiodonties.p2_indekskalkulus_rb_el31_b,
    emrperiodonties.p2_indekskalkulus_rb_el41_b,
    emrperiodonties.p2_indekskalkulus_rb_el42_b,
    emrperiodonties.p2_indekskalkulus_rb_el46_b,
    emrperiodonties.p2_indekskalkulus_rb_el36_l,
    emrperiodonties.p2_indekskalkulus_rb_el34_l,
    emrperiodonties.p2_indekskalkulus_rb_el32_l,
    emrperiodonties.p2_indekskalkulus_rb_el31_l,
    emrperiodonties.p2_indekskalkulus_rb_el41_l,
    emrperiodonties.p2_indekskalkulus_rb_el42_l,
    emrperiodonties.p2_indekskalkulus_rb_el46_l,
    emrperiodonties.p3_tanggal,
    emrperiodonties.p3_indeksplak_ra_el16_b,
    emrperiodonties.p3_indeksplak_ra_el12_b,
    emrperiodonties.p3_indeksplak_ra_el11_b,
    emrperiodonties.p3_indeksplak_ra_el21_b,
    emrperiodonties.p3_indeksplak_ra_el22_b,
    emrperiodonties.p3_indeksplak_ra_el24_b,
    emrperiodonties.p3_indeksplak_ra_el26_b,
    emrperiodonties.p3_indeksplak_ra_el16_l,
    emrperiodonties.p3_indeksplak_ra_el12_l,
    emrperiodonties.p3_indeksplak_ra_el11_l,
    emrperiodonties.p3_indeksplak_ra_el21_l,
    emrperiodonties.p3_indeksplak_ra_el22_l,
    emrperiodonties.p3_indeksplak_ra_el24_l,
    emrperiodonties.p3_indeksplak_ra_el26_l,
    emrperiodonties.p3_indeksplak_rb_el36_b,
    emrperiodonties.p3_indeksplak_rb_el34_b,
    emrperiodonties.p3_indeksplak_rb_el32_b,
    emrperiodonties.p3_indeksplak_rb_el31_b,
    emrperiodonties.p3_indeksplak_rb_el41_b,
    emrperiodonties.p3_indeksplak_rb_el42_b,
    emrperiodonties.p3_indeksplak_rb_el46_b,
    emrperiodonties.p3_indeksplak_rb_el36_l,
    emrperiodonties.p3_indeksplak_rb_el34_l,
    emrperiodonties.p3_indeksplak_rb_el32_l,
    emrperiodonties.p3_indeksplak_rb_el31_l,
    emrperiodonties.p3_indeksplak_rb_el41_l,
    emrperiodonties.p3_indeksplak_rb_el42_l,
    emrperiodonties.p3_indeksplak_rb_el46_l,
    emrperiodonties.p3_bop_ra_el16_b,
    emrperiodonties.p3_bop_ra_el12_b,
    emrperiodonties.p3_bop_ra_el11_b,
    emrperiodonties.p3_bop_ra_el21_b,
    emrperiodonties.p3_bop_ra_el22_b,
    emrperiodonties.p3_bop_ra_el24_b,
    emrperiodonties.p3_bop_ra_el26_b,
    emrperiodonties.p3_bop_ra_el16_l,
    emrperiodonties.p3_bop_ra_el12_l,
    emrperiodonties.p3_bop_ra_el11_l,
    emrperiodonties.p3_bop_ra_el21_l,
    emrperiodonties.p3_bop_ra_el22_l,
    emrperiodonties.p3_bop_ra_el24_l,
    emrperiodonties.p3_bop_ra_el26_l,
    emrperiodonties.p3_bop_rb_el36_b,
    emrperiodonties.p3_bop_rb_el34_b,
    emrperiodonties.p3_bop_rb_el32_b,
    emrperiodonties.p3_bop_rb_el31_b,
    emrperiodonties.p3_bop_rb_el41_b,
    emrperiodonties.p3_bop_rb_el42_b,
    emrperiodonties.p3_bop_rb_el46_b,
    emrperiodonties.p3_bop_rb_el36_l,
    emrperiodonties.p3_bop_rb_el34_l,
    emrperiodonties.p3_bop_rb_el32_l,
    emrperiodonties.p3_bop_rb_el31_l,
    emrperiodonties.p3_bop_rb_el41_l,
    emrperiodonties.p3_bop_rb_el42_l,
    emrperiodonties.p3_bop_rb_el46_l,
    emrperiodonties.p3_indekskalkulus_ra_el16_b,
    emrperiodonties.p3_indekskalkulus_ra_el26_b,
    emrperiodonties.p3_indekskalkulus_ra_el16_l,
    emrperiodonties.p3_indekskalkulus_ra_el26_l,
    emrperiodonties.p3_indekskalkulus_rb_el36_b,
    emrperiodonties.p3_indekskalkulus_rb_el34_b,
    emrperiodonties.p3_indekskalkulus_rb_el32_b,
    emrperiodonties.p3_indekskalkulus_rb_el31_b,
    emrperiodonties.p3_indekskalkulus_rb_el41_b,
    emrperiodonties.p3_indekskalkulus_rb_el42_b,
    emrperiodonties.p3_indekskalkulus_rb_el46_b,
    emrperiodonties.p3_indekskalkulus_rb_el36_l,
    emrperiodonties.p3_indekskalkulus_rb_el34_l,
    emrperiodonties.p3_indekskalkulus_rb_el32_l,
    emrperiodonties.p3_indekskalkulus_rb_el31_l,
    emrperiodonties.p3_indekskalkulus_rb_el41_l,
    emrperiodonties.p3_indekskalkulus_rb_el42_l,
    emrperiodonties.p3_indekskalkulus_rb_el46_l,
    emrperiodonties.foto_klinis_oklusi_arah_kiri,
    emrperiodonties.foto_klinis_oklusi_arah_kanan,
    emrperiodonties.foto_klinis_oklusi_arah_anterior,
    emrperiodonties.foto_klinis_oklusal_rahang_atas,
    emrperiodonties.foto_klinis_oklusal_rahang_bawah,
    emrperiodonties.foto_klinis_before,
    emrperiodonties.foto_klinis_after,
    emrperiodonties.foto_ronsen_panoramik,
    emrperiodonties.terapi_s,
    emrperiodonties.terapi_o,
    emrperiodonties.terapi_a,
    emrperiodonties.terapi_p,
    emrperiodonties.terapi_ohis,
    emrperiodonties.terapi_bop,
    emrperiodonties.terapi_pm18,
    emrperiodonties.terapi_pm17,
    emrperiodonties.terapi_pm16,
    emrperiodonties.terapi_pm15,
    emrperiodonties.terapi_pm14,
    emrperiodonties.terapi_pm13,
    emrperiodonties.terapi_pm12,
    emrperiodonties.terapi_pm11,
    emrperiodonties.terapi_pm21,
    emrperiodonties.terapi_pm22,
    emrperiodonties.terapi_pm23,
    emrperiodonties.terapi_pm24,
    emrperiodonties.terapi_pm25,
    emrperiodonties.terapi_pm26,
    emrperiodonties.terapi_pm27,
    emrperiodonties.terapi_pm28,
    emrperiodonties.terapi_pm38,
    emrperiodonties.terapi_pm37,
    emrperiodonties.terapi_pm36,
    emrperiodonties.terapi_pm35,
    emrperiodonties.terapi_pm34,
    emrperiodonties.terapi_pm33,
    emrperiodonties.terapi_pm32,
    emrperiodonties.terapi_pm31,
    emrperiodonties.terapi_pm41,
    emrperiodonties.terapi_pm42,
    emrperiodonties.terapi_pm43,
    emrperiodonties.terapi_pm44,
    emrperiodonties.terapi_pm45,
    emrperiodonties.terapi_pm46,
    emrperiodonties.terapi_pm47,
    emrperiodonties.terapi_pm48,
    emrperiodonties.terapi_pb18,
    emrperiodonties.terapi_pb17,
    emrperiodonties.terapi_pb16,
    emrperiodonties.terapi_pb15,
    emrperiodonties.terapi_pb14,
    emrperiodonties.terapi_pb13,
    emrperiodonties.terapi_pb12,
    emrperiodonties.terapi_pb11,
    emrperiodonties.terapi_pb21,
    emrperiodonties.terapi_pb22,
    emrperiodonties.terapi_pb23,
    emrperiodonties.terapi_pb24,
    emrperiodonties.terapi_pb25,
    emrperiodonties.terapi_pb26,
    emrperiodonties.terapi_pb27,
    emrperiodonties.terapi_pb28,
    emrperiodonties.terapi_pb38,
    emrperiodonties.terapi_pb37,
    emrperiodonties.terapi_pb36,
    emrperiodonties.terapi_pb35,
    emrperiodonties.terapi_pb34,
    emrperiodonties.terapi_pb33,
    emrperiodonties.terapi_pb32,
    emrperiodonties.terapi_pb31,
    emrperiodonties.terapi_pb41,
    emrperiodonties.terapi_pb42,
    emrperiodonties.terapi_pb43,
    emrperiodonties.terapi_pb44,
    emrperiodonties.terapi_pb45,
    emrperiodonties.terapi_pb46,
    emrperiodonties.terapi_pb47,
    emrperiodonties.terapi_pb48,
    emrperiodonties.terapi_pd18,
    emrperiodonties.terapi_pd17,
    emrperiodonties.terapi_pd16,
    emrperiodonties.terapi_pd15,
    emrperiodonties.terapi_pd14,
    emrperiodonties.terapi_pd13,
    emrperiodonties.terapi_pd12,
    emrperiodonties.terapi_pd11,
    emrperiodonties.terapi_pd21,
    emrperiodonties.terapi_pd22,
    emrperiodonties.terapi_pd23,
    emrperiodonties.terapi_pd24,
    emrperiodonties.terapi_pd25,
    emrperiodonties.terapi_pd26,
    emrperiodonties.terapi_pd27,
    emrperiodonties.terapi_pd28,
    emrperiodonties.terapi_pd38,
    emrperiodonties.terapi_pd37,
    emrperiodonties.terapi_pd36,
    emrperiodonties.terapi_pd35,
    emrperiodonties.terapi_pd34,
    emrperiodonties.terapi_pd33,
    emrperiodonties.terapi_pd32,
    emrperiodonties.terapi_pd31,
    emrperiodonties.terapi_pd41,
    emrperiodonties.terapi_pd42,
    emrperiodonties.terapi_pd43,
    emrperiodonties.terapi_pd44,
    emrperiodonties.terapi_pd45,
    emrperiodonties.terapi_pd46,
    emrperiodonties.terapi_pd47,
    emrperiodonties.terapi_pd48,
    emrperiodonties.terapi_pl18,
    emrperiodonties.terapi_pl17,
    emrperiodonties.terapi_pl16,
    emrperiodonties.terapi_pl15,
    emrperiodonties.terapi_pl14,
    emrperiodonties.terapi_pl13,
    emrperiodonties.terapi_pl12,
    emrperiodonties.terapi_pl11,
    emrperiodonties.terapi_pl21,
    emrperiodonties.terapi_pl22,
    emrperiodonties.terapi_pl23,
    emrperiodonties.terapi_pl24,
    emrperiodonties.terapi_pl25,
    emrperiodonties.terapi_pl26,
    emrperiodonties.terapi_pl27,
    emrperiodonties.terapi_pl28,
    emrperiodonties.terapi_pl38,
    emrperiodonties.terapi_pl37,
    emrperiodonties.terapi_pl36,
    emrperiodonties.terapi_pl35,
    emrperiodonties.terapi_pl34,
    emrperiodonties.terapi_pl33,
    emrperiodonties.terapi_pl32,
    emrperiodonties.terapi_pl31,
    emrperiodonties.terapi_pl41,
    emrperiodonties.terapi_pl42,
    emrperiodonties.terapi_pl43,
    emrperiodonties.terapi_pl44,
    emrperiodonties.terapi_pl45,
    emrperiodonties.terapi_pl46,
    emrperiodonties.terapi_pl47,
    emrperiodonties.terapi_pl48,
    emrperiodonties.created_at,
    emrperiodonties.updated_at,
    emrperiodonties.status_emr,
    emrperiodonties.status_penilaian
   FROM public.emrperiodonties;


ALTER TABLE public.view_history_emrperiodonties OWNER TO rsyarsi;

--
-- TOC entry 266 (class 1259 OID 16668)
-- Name: view_history_emrprostodonties; Type: VIEW; Schema: public; Owner: rsyarsi
--

CREATE VIEW public.view_history_emrprostodonties AS
 SELECT emrprostodonties.id,
    emrprostodonties.noregister,
    emrprostodonties.noepisode,
    emrprostodonties.nomorrekammedik,
    emrprostodonties.tanggal,
    emrprostodonties.namapasien,
    emrprostodonties.pekerjaan,
    emrprostodonties.jeniskelamin,
    emrprostodonties.alamatpasien,
    emrprostodonties.namaoperator,
    emrprostodonties.nomortelpon,
    emrprostodonties.npm,
    emrprostodonties.keluhanutama,
    emrprostodonties.riwayatgeligi,
    emrprostodonties.pengalamandengangigitiruan,
    emrprostodonties.estetis,
    emrprostodonties.fungsibicara,
    emrprostodonties.penguyahan,
    emrprostodonties.pembiayaan,
    emrprostodonties.lainlain,
    emrprostodonties.wajah,
    emrprostodonties.profilmuka,
    emrprostodonties.pupil,
    emrprostodonties.tragus,
    emrprostodonties.hidung,
    emrprostodonties.pernafasanmelaluihidung,
    emrprostodonties.bibiratas,
    emrprostodonties.bibiratas_b,
    emrprostodonties.bibirbawah,
    emrprostodonties.bibirbawah_b,
    emrprostodonties.submandibulariskanan,
    emrprostodonties.submandibulariskanan_b,
    emrprostodonties.submandibulariskiri,
    emrprostodonties.submandibulariskiri_b,
    emrprostodonties.sublingualis,
    emrprostodonties.sublingualis_b,
    emrprostodonties.sisikiri,
    emrprostodonties.sisikirisejak,
    emrprostodonties.sisikanan,
    emrprostodonties.sisikanansejak,
    emrprostodonties.membukamulut,
    emrprostodonties.membukamulut_b,
    emrprostodonties.kelainanlain,
    emrprostodonties.higienemulut,
    emrprostodonties.salivakuantitas,
    emrprostodonties.salivakonsisten,
    emrprostodonties.lidahukuran,
    emrprostodonties.lidahposisiwright,
    emrprostodonties.lidahmobilitas,
    emrprostodonties.refleksmuntah,
    emrprostodonties.mukosamulut,
    emrprostodonties.mukosamulutberupa,
    emrprostodonties.gigitan,
    emrprostodonties.gigitanbilaada,
    emrprostodonties.gigitanterbuka,
    emrprostodonties.gigitanterbukaregion,
    emrprostodonties.gigitansilang,
    emrprostodonties.gigitansilangregion,
    emrprostodonties.hubunganrahang,
    emrprostodonties.pemeriksaanrontgendental,
    emrprostodonties.elemengigi,
    emrprostodonties.pemeriksaanrontgenpanoramik,
    emrprostodonties.pemeriksaanrontgentmj,
    emrprostodonties.frakturgigi,
    emrprostodonties.frakturarah,
    emrprostodonties.frakturbesar,
    emrprostodonties.intraorallainlain,
    emrprostodonties.perbandinganmahkotadanakargigi,
    emrprostodonties.interprestasifotorontgen,
    emrprostodonties.intraoralkebiasaanburuk,
    emrprostodonties.intraoralkebiasaanburukberupa,
    emrprostodonties.pemeriksaanodontogram_11_51,
    emrprostodonties.pemeriksaanodontogram_12_52,
    emrprostodonties.pemeriksaanodontogram_13_53,
    emrprostodonties.pemeriksaanodontogram_14_54,
    emrprostodonties.pemeriksaanodontogram_15_55,
    emrprostodonties.pemeriksaanodontogram_16,
    emrprostodonties.pemeriksaanodontogram_17,
    emrprostodonties.pemeriksaanodontogram_18,
    emrprostodonties.pemeriksaanodontogram_61_21,
    emrprostodonties.pemeriksaanodontogram_62_22,
    emrprostodonties.pemeriksaanodontogram_63_23,
    emrprostodonties.pemeriksaanodontogram_64_24,
    emrprostodonties.pemeriksaanodontogram_65_25,
    emrprostodonties.pemeriksaanodontogram_26,
    emrprostodonties.pemeriksaanodontogram_27,
    emrprostodonties.pemeriksaanodontogram_28,
    emrprostodonties.pemeriksaanodontogram_48,
    emrprostodonties.pemeriksaanodontogram_47,
    emrprostodonties.pemeriksaanodontogram_46,
    emrprostodonties.pemeriksaanodontogram_45_85,
    emrprostodonties.pemeriksaanodontogram_44_84,
    emrprostodonties.pemeriksaanodontogram_43_83,
    emrprostodonties.pemeriksaanodontogram_42_82,
    emrprostodonties.pemeriksaanodontogram_41_81,
    emrprostodonties.pemeriksaanodontogram_38,
    emrprostodonties.pemeriksaanodontogram_37,
    emrprostodonties.pemeriksaanodontogram_36,
    emrprostodonties.pemeriksaanodontogram_75_35,
    emrprostodonties.pemeriksaanodontogram_74_34,
    emrprostodonties.pemeriksaanodontogram_73_33,
    emrprostodonties.pemeriksaanodontogram_72_32,
    emrprostodonties.pemeriksaanodontogram_71_31,
    emrprostodonties.rahangataspostkiri,
    emrprostodonties.rahangataspostkanan,
    emrprostodonties.rahangatasanterior,
    emrprostodonties.rahangbawahpostkiri,
    emrprostodonties.rahangbawahpostkanan,
    emrprostodonties.rahangbawahanterior,
    emrprostodonties.rahangatasbentukpostkiri,
    emrprostodonties.rahangatasbentukpostkanan,
    emrprostodonties.rahangatasbentukanterior,
    emrprostodonties.rahangatasketinggianpostkiri,
    emrprostodonties.rahangatasketinggianpostkanan,
    emrprostodonties.rahangatasketinggiananterior,
    emrprostodonties.rahangatastahananjaringanpostkiri,
    emrprostodonties.rahangatastahananjaringanpostkanan,
    emrprostodonties.rahangatastahananjaringananterior,
    emrprostodonties.rahangatasbentukpermukaanpostkiri,
    emrprostodonties.rahangatasbentukpermukaanpostkanan,
    emrprostodonties.rahangatasbentukpermukaananterior,
    emrprostodonties.rahangbawahbentukpostkiri,
    emrprostodonties.rahangbawahbentukpostkanan,
    emrprostodonties.rahangbawahbentukanterior,
    emrprostodonties.rahangbawahketinggianpostkiri,
    emrprostodonties.rahangbawahketinggianpostkanan,
    emrprostodonties.rahangbawahketinggiananterior,
    emrprostodonties.rahangbawahtahananjaringanpostkiri,
    emrprostodonties.rahangbawahtahananjaringanpostkanan,
    emrprostodonties.rahangbawahtahananjaringananterior,
    emrprostodonties.rahangbawahbentukpermukaanpostkiri,
    emrprostodonties.rahangbawahbentukpermukaanpostkanan,
    emrprostodonties.rahangbawahbentukpermukaananterior,
    emrprostodonties.anterior,
    emrprostodonties.prosteriorkiri,
    emrprostodonties.prosteriorkanan,
    emrprostodonties.labialissuperior,
    emrprostodonties.labialisinferior,
    emrprostodonties.bukalisrahangataskiri,
    emrprostodonties.bukalisrahangataskanan,
    emrprostodonties.bukalisrahangbawahkiri,
    emrprostodonties.bukalisrahangbawahkanan,
    emrprostodonties.lingualis,
    emrprostodonties.palatum,
    emrprostodonties.kedalaman,
    emrprostodonties.toruspalatinus,
    emrprostodonties.palatummolle,
    emrprostodonties.tuberorositasalveolariskiri,
    emrprostodonties.tuberorositasalveolariskanan,
    emrprostodonties.ruangretromilahioidkiri,
    emrprostodonties.ruangretromilahioidkanan,
    emrprostodonties.bentuklengkungrahangatas,
    emrprostodonties.bentuklengkungrahangbawah,
    emrprostodonties.perlekatandasarmulut,
    emrprostodonties.pemeriksaanlain_lainlain,
    emrprostodonties.sikapmental,
    emrprostodonties.diagnosa,
    emrprostodonties.rahangatas,
    emrprostodonties.rahangataselemen,
    emrprostodonties.rahangbawah,
    emrprostodonties.rahangbawahelemen,
    emrprostodonties.gigitiruancekat,
    emrprostodonties.gigitiruancekatelemen,
    emrprostodonties.perawatanperiodontal,
    emrprostodonties.perawatanbedah,
    emrprostodonties.perawatanbedah_ada,
    emrprostodonties.perawatanbedahelemen,
    emrprostodonties.perawatanbedahlainlain,
    emrprostodonties.konservasigigi,
    emrprostodonties.konservasigigielemen,
    emrprostodonties.rekonturing,
    emrprostodonties.adapembuatanmahkota,
    emrprostodonties.pengasahangigimiring,
    emrprostodonties.pengasahangigiextruded,
    emrprostodonties.rekonturinglainlain,
    emrprostodonties.macamcetakan_ra,
    emrprostodonties.acamcetakan_rb,
    emrprostodonties.warnagigi,
    emrprostodonties.klasifikasidaerahtidakbergigirahangatas,
    emrprostodonties.klasifikasidaerahtidakbergigirahangbawah,
    emrprostodonties.gigipenyangga,
    emrprostodonties.direk,
    emrprostodonties.indirek,
    emrprostodonties.platdasar,
    emrprostodonties.anasirgigi,
    emrprostodonties.prognosis,
    emrprostodonties.prognosisalasan,
    emrprostodonties.reliningregio,
    emrprostodonties.reliningregiotanggal,
    emrprostodonties.reparasiregio,
    emrprostodonties.reparasiregiotanggal,
    emrprostodonties.perawatanulangsebab,
    emrprostodonties.perawatanulanglainlain,
    emrprostodonties.perawatanulanglainlaintanggal,
    emrprostodonties.perawatanulangketerangan,
    emrprostodonties.created_at,
    emrprostodonties.updated_at,
    emrprostodonties.nim,
    emrprostodonties.designngigi,
    emrprostodonties.designngigitext,
    emrprostodonties.fotoodontogram,
    emrprostodonties.status_emr,
    emrprostodonties.status_penilaian
   FROM public.emrprostodonties;


ALTER TABLE public.view_history_emrprostodonties OWNER TO rsyarsi;

--
-- TOC entry 267 (class 1259 OID 16673)
-- Name: view_history_emrradiologies; Type: VIEW; Schema: public; Owner: rsyarsi
--

CREATE VIEW public.view_history_emrradiologies AS
 SELECT emrradiologies.id,
    emrradiologies.noepisode,
    emrradiologies.noregistrasi,
    emrradiologies.nomr,
    emrradiologies.namapasien,
    emrradiologies.alamat,
    emrradiologies.usia,
    emrradiologies.tglpotret,
    emrradiologies.diagnosaklinik,
    emrradiologies.foto,
    emrradiologies.jenisradiologi,
    emrradiologies.periaprikal_int_mahkota,
    emrradiologies.periaprikal_int_akar,
    emrradiologies.periaprikal_int_membran,
    emrradiologies.periaprikal_int_lamina_dura,
    emrradiologies.periaprikal_int_furkasi,
    emrradiologies.periaprikal_int_alveoral,
    emrradiologies.periaprikal_int_kondisi_periaprikal,
    emrradiologies.periaprikal_int_kesan,
    emrradiologies.periaprikal_int_lesigigi,
    emrradiologies.periaprikal_int_suspek,
    emrradiologies.nim,
    emrradiologies.namaoperator,
    emrradiologies.namadokter,
    emrradiologies.panoramik_miising_teeth,
    emrradiologies.panoramik_missing_agnesia,
    emrradiologies.panoramik_persistensi,
    emrradiologies.panoramik_impaki,
    emrradiologies.panoramik_kondisi_mahkota,
    emrradiologies.panoramik_kondisi_akar,
    emrradiologies.panoramik_kondisi_alveoral,
    emrradiologies.panoramik_kondisi_periaprikal,
    emrradiologies.panoramik_area_dua,
    emrradiologies.oklusal_kesan,
    emrradiologies.oklusal_suspek_radiognosis,
    emrradiologies.status_emr,
    emrradiologies.status_penilaian,
    emrradiologies.jenis_radiologi
   FROM public.emrradiologies;


ALTER TABLE public.view_history_emrradiologies OWNER TO rsyarsi;

--
-- TOC entry 268 (class 1259 OID 16678)
-- Name: viewabsencemonthreport; Type: VIEW; Schema: public; Owner: rsyarsi
--

CREATE VIEW public.viewabsencemonthreport AS
 SELECT a.id,
    a.studentid,
    b.name,
    a.time_in,
    a.time_out,
    a.periode,
    b.nim
   FROM (public.absencestudents a
     JOIN public.students b ON ((a.studentid = b.id)));


ALTER TABLE public.viewabsencemonthreport OWNER TO rsyarsi;

--
-- TOC entry 269 (class 1259 OID 16682)
-- Name: viewassesmentdetailbygrouptypes; Type: VIEW; Schema: public; Owner: rsyarsi
--

CREATE VIEW public.viewassesmentdetailbygrouptypes AS
 SELECT b.id AS assesmentdetailid,
    b.assesmentdescription,
    b.assesmentskalavalue,
    b.assesmentbobotvalue,
    a.active AS activeassesmentgroups,
    b.active AS activeassesmentdetails,
    c.active AS activespecialists,
    a.id AS assesmentgroupid,
    a.type AS assesmentgrouptype,
    b.kodesub,
    b.index_sub,
    b.assesmentnumbers,
    b.kode_sub_name,
    b.assesmentkonditevalue,
    b.assesmentkonditevaluestart,
    b.assesmentkonditevalueend
   FROM ((public.assesmentgroups a
     JOIN public.assesmentdetails b ON ((a.id = b.assesmentgroupid)))
     JOIN public.specialists c ON ((c.id = a.specialistid)));


ALTER TABLE public.viewassesmentdetailbygrouptypes OWNER TO rsyarsi;

--
-- TOC entry 270 (class 1259 OID 16687)
-- Name: years; Type: TABLE; Schema: public; Owner: rsyarsi
--

CREATE TABLE public.years (
    id uuid NOT NULL,
    name character varying(4) NOT NULL,
    active integer DEFAULT 1 NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.years OWNER TO rsyarsi;

--
-- TOC entry 271 (class 1259 OID 16691)
-- Name: viewtrsassesmentheader; Type: VIEW; Schema: public; Owner: rsyarsi
--

CREATE VIEW public.viewtrsassesmentheader AS
 SELECT a.id,
    a.active,
    a.assesmentgroupid,
    b.assementgroupname,
    a.studentid,
    c.name AS studentname,
    c.nim,
    a.lectureid,
    d.name AS lecturename,
    a.yearid,
    e.name AS yearname,
    a.semesterid,
    f.semestername,
    a.specialistid,
    g.specialistname,
    a.totalbobot,
    a.grandotal,
    a.assesmenttype,
    a.created_at,
    a.updated_at,
    a.lock
   FROM ((((((public.trsassesments a
     JOIN public.assesmentgroups b ON ((a.assesmentgroupid = b.id)))
     JOIN public.students c ON ((c.id = a.studentid)))
     JOIN public.lectures d ON ((d.id = a.lectureid)))
     JOIN public.years e ON ((e.id = a.yearid)))
     JOIN public.semesters f ON ((f.id = a.semesterid)))
     JOIN public.specialists g ON ((g.id = a.specialistid)));


ALTER TABLE public.viewtrsassesmentheader OWNER TO rsyarsi;

--
-- TOC entry 3454 (class 2604 OID 16696)
-- Name: failed_jobs id; Type: DEFAULT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.failed_jobs ALTER COLUMN id SET DEFAULT nextval('public.failed_jobs_id_seq'::regclass);


--
-- TOC entry 3461 (class 2604 OID 16697)
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- TOC entry 3462 (class 2604 OID 16698)
-- Name: personal_access_tokens id; Type: DEFAULT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.personal_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.personal_access_tokens_id_seq'::regclass);


--
-- TOC entry 3706 (class 0 OID 16423)
-- Dependencies: 214
-- Data for Name: absencestudents; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.absencestudents (id, studentid, time_in, time_out, date, statusabsensi, updated_at, created_at, periode) FROM stdin;
cc624137-c31d-4e83-881c-aab63de5cc48	db9f2b64-30fb-415e-bff5-e02d870862b1	2024-03-27 13:43:57	\N	2024-03-27	IN	\N	\N	2024-03
1b6e8502-14d5-4a3c-92fb-fe92d89ff483	f95f6c6c-aeed-44d0-acd6-53e900611129	2024-05-08 15:34:38	\N	2024-05-08	IN	\N	\N	2024-05
c4b4f92c-825d-4061-aac7-6c9005b67f25	9b609659-0c7e-492c-a49f-04a3ceeccbb0	2024-05-08 15:34:42	\N	2024-05-08	IN	\N	\N	2024-05
478c2c36-ef22-4fa4-89a6-2ecce9ed7477	3b358ee0-c278-4cee-8c99-55d87d2bc142	2024-05-08 15:40:01	\N	2024-05-08	IN	\N	\N	2024-05
5c082992-a9f5-4492-85f2-574f90ada24c	97ae28a1-f02b-4b68-9459-599d87845fc7	2024-05-15 21:26:41	\N	2024-05-15	IN	\N	\N	2024-05
0d6fa6a7-e740-4692-a427-93f6d4381e69	41661e2e-0c83-4282-b67e-8c68037fa498	2024-05-22 10:40:57	\N	2024-05-22	IN	2024-05-22 10:40:57	\N	2024-05
452f0998-6fcd-4de3-a3d3-0f13c87a37c4	54be3d06-dec5-4ec0-82d9-fd11ee818217	2024-05-27 07:55:48	\N	2024-05-27	IN	\N	\N	2024-05
24121502-9182-4abb-ad14-16936c076cdc	a9c3e3af-a31e-4ab0-be8d-f7035c065805	2024-05-27 08:33:21	\N	2024-05-27	IN	\N	\N	2024-05
00e9d0da-eaf4-40ec-86bd-02a269bc06d8	eadbbcdf-4dca-4aaa-aab3-fede3019d756	2024-05-27 08:43:49	\N	2024-05-27	IN	\N	\N	2024-05
363f6c06-7929-4c30-acd0-ea33844aca17	f95f6c6c-aeed-44d0-acd6-53e900611129	2024-05-27 11:26:42	\N	2024-05-27	IN	\N	\N	2024-05
5cc02370-6b4c-4526-b23b-ee6c9aaad1de	515b8bca-8641-497e-8cea-652286f98d56	2024-05-27 13:05:29	\N	2024-05-27	IN	2024-05-27 13:05:29	\N	2024-05
c7bb2586-df3c-498d-9860-93a24a69ed32	254fbe52-438a-4e69-963c-1103a4482b51	2024-05-27 23:10:53	\N	2024-05-27	IN	\N	\N	2024-05
ee8e3d30-6891-4d62-91e6-e69b820cbf97	254fbe52-438a-4e69-963c-1103a4482b51	2024-05-28 07:47:00	\N	2024-05-28	IN	\N	\N	2024-05
e120b26f-406b-4388-96c7-9488f45fe2e5	29cfee77-5f9a-4ab5-934d-f4973664092b	2024-05-28 08:44:16	\N	2024-05-28	IN	\N	\N	2024-05
cb94ce2c-9d73-419b-8666-da0e83983e47	3b358ee0-c278-4cee-8c99-55d87d2bc142	2024-05-28 08:47:46	\N	2024-05-28	IN	2024-05-28 08:47:46	\N	2024-05
8f1e880b-67d6-4c0f-8a2b-f4670c768da9	a9c3e3af-a31e-4ab0-be8d-f7035c065805	2024-05-28 09:17:42	\N	2024-05-28	IN	\N	\N	2024-05
6660d83e-1b5e-4488-90c9-6f4dbb7270fe	847d4b7b-d2d4-4711-a3c8-793b8e046886	2024-05-28 09:19:59	\N	2024-05-28	IN	\N	\N	2024-05
e7898ed4-5d62-46b8-8432-a40a5a13959d	515b8bca-8641-497e-8cea-652286f98d56	2024-05-28 09:24:30	\N	2024-05-28	IN	\N	\N	2024-05
\.


--
-- TOC entry 3707 (class 0 OID 16426)
-- Dependencies: 215
-- Data for Name: assesmentdetails; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.assesmentdetails (id, assesmentgroupid, assesmentnumbers, assesmentdescription, assesmentbobotvalue, assesmentskalavalue, assesmentskalavaluestart, assesmentskalavalueend, assesmentkonditevalue, assesmentkonditevaluestart, assesmentkonditevalueend, active, created_at, updated_at, assesmentvaluestart, assesmentvalueend, kodesub, index_sub, kode_sub_name) FROM stdin;
636d8493-7327-46bd-b9f2-9c8b8b30e3b7	c844e587-0cff-487a-a81f-b5406215a1e8	1	Pekerjaan	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	Pekerjaan
b01d7ab9-48c0-42d6-a73a-3e89e1700662	c844e587-0cff-487a-a81f-b5406215a1e8	2	Indikasi	0	10	7	10	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
a88aa365-5367-43b7-b8b2-6cc50ddd19fd	c844e587-0cff-487a-a81f-b5406215a1e8	3	Preparasi	0	20	10	20	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
e1e03caa-1b2e-4a2d-a3b2-0cd8ffb42915	c844e587-0cff-487a-a81f-b5406215a1e8	4	Isolasi daerah kerja	0	10	8	10	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
e7e3952b-2882-4ee0-99e1-dca0afebed48	c844e587-0cff-487a-a81f-b5406215a1e8	5	Liner, Etsa dan Bonding	0	40	23	40	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
762e0417-2ced-46e2-bd01-9b28f1b91231	c844e587-0cff-487a-a81f-b5406215a1e8	6	Penumpatan komposit	0	40	23	40	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
78a9dc27-194e-4bae-8756-baa5159c785d	c844e587-0cff-487a-a81f-b5406215a1e8	7	Finishing dan polishing	0	10	7	10	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
de8a1a07-d720-4ad7-bf42-846cf4eb3ac8	c844e587-0cff-487a-a81f-b5406215a1e8	8	Kontrol	0	10	5	10	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
208de0d0-2f2f-489c-8009-a4f64b98d76f	c844e587-0cff-487a-a81f-b5406215a1e8	9	Sikap	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	Sikap
0d802a0f-26a5-468a-9372-4d48e59dfc41	c844e587-0cff-487a-a81f-b5406215a1e8	9	Inisiatif dan komunikasi	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
374fc9f3-503e-4558-ba94-7f2688a5e7a8	c844e587-0cff-487a-a81f-b5406215a1e8	10	Disiplin	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
b43c94c8-3ec1-43fc-a443-906ceee457d2	c844e587-0cff-487a-a81f-b5406215a1e8	11	Kejujuran	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
ea32d02d-5aa2-49ff-80e5-be78ae9eb218	c844e587-0cff-487a-a81f-b5406215a1e8	12	Tanggung jawab	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
e3d23c0f-6f02-43e0-8b8e-cdc3b222f425	c844e587-0cff-487a-a81f-b5406215a1e8	13	Sopan santun	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
9f5b57af-6fff-4622-9e66-bb8ddb6098e6	061105f4-25d6-4def-9849-07f2c521f33d	1	Pekerjaan	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	Pekerjaan
f2da3b8b-7303-43e7-829c-bd62e5f63d3f	061105f4-25d6-4def-9849-07f2c521f33d	2	Indikasi	0	8	6	8	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
821ca840-ba02-4511-bca7-51a6ea717e57	061105f4-25d6-4def-9849-07f2c521f33d	3	Preparasi	0	20	10	20	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
f67bdfad-86ad-415d-9bcd-d0bc28997d23	061105f4-25d6-4def-9849-07f2c521f33d	4	Isolasi daerah kerja	0	9	7	9	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
70dc5f2f-ea05-4bd2-8be6-da5eb8e2a701	061105f4-25d6-4def-9849-07f2c521f33d	5	Pemasangan matriks	0	9	7	9	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
ad045742-7f7c-472b-9d71-9ea56c500205	061105f4-25d6-4def-9849-07f2c521f33d	6	Liner, Etsa dan Bonding	0	36	20	36	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
9dca9bb2-1f3d-4aff-816e-e10b631da4bd	061105f4-25d6-4def-9849-07f2c521f33d	7	Penumpatan komposit	0	36	20	36	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
54232435-4002-4d49-8acc-61d19637f95b	061105f4-25d6-4def-9849-07f2c521f33d	8	Finishing dan polishing	0	9	5	9	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
1b6824e3-7775-493d-80f5-b67c736b32f2	061105f4-25d6-4def-9849-07f2c521f33d	9	Kontrol	0	9	5	9	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
f9a2a144-2851-46c6-87e5-38ddc286069f	061105f4-25d6-4def-9849-07f2c521f33d	10	Sikap	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	Sikap
6905038a-8c9f-4461-b2ae-785dad0a5db0	061105f4-25d6-4def-9849-07f2c521f33d	11	Inisiatif dan komunikasi	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
d6799d41-f2db-45be-838c-94cf13d5b362	061105f4-25d6-4def-9849-07f2c521f33d	12	Disiplin	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
30a52211-b9e8-42b0-869e-f5f4a0d937e0	061105f4-25d6-4def-9849-07f2c521f33d	13	Kejujuran	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
b109dd6e-5174-438a-bb4d-dcbf7a064885	061105f4-25d6-4def-9849-07f2c521f33d	14	Tanggung jawab	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
cfbf1a94-88d4-4b07-97e2-38e8cece4f59	061105f4-25d6-4def-9849-07f2c521f33d	15	Sopan santun	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
ad962ad5-50ed-49da-94c4-e84a19f3e53b	596b9232-d58b-4f11-83ca-5afe81fce60c	1	Pekerjaan	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	Pekerjaan
b1a97851-1d4a-409c-8c22-c5eff6b1812e	596b9232-d58b-4f11-83ca-5afe81fce60c	2	Indikasi	0	8	6	8	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
487e98c5-17c9-40e8-8612-820c78743e80	596b9232-d58b-4f11-83ca-5afe81fce60c	3	Preparasi	0	20	10	20	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
7e5e3e26-17d3-4817-8503-5d307c6a86e6	596b9232-d58b-4f11-83ca-5afe81fce60c	4	Isolasi daerah kerja	0	9	7	9	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
e7fcf8f9-a3d9-471c-9b55-8b682e20c78d	596b9232-d58b-4f11-83ca-5afe81fce60c	5	Pemasangan matriks	0	9	7	9	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
89231dcf-9183-406e-9b93-7dd68850986e	596b9232-d58b-4f11-83ca-5afe81fce60c	6	Liner, Etsa dan Bonding	0	36	20	36	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
990d3d91-bb32-411f-9ed1-6ec333e66b59	596b9232-d58b-4f11-83ca-5afe81fce60c	7	Penumpatan komposit	0	36	20	36	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
ccfd5aed-94e8-4e5c-b82f-1ade4308c99f	596b9232-d58b-4f11-83ca-5afe81fce60c	8	Finishing dan polishing	0	9	5	9	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
fbf9cbdd-7b4c-458d-b1c4-6909e9f09b1d	596b9232-d58b-4f11-83ca-5afe81fce60c	9	Kontrol	0	9	5	9	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
c3ecef61-deb0-49c6-9e6d-d02bb5930ef9	596b9232-d58b-4f11-83ca-5afe81fce60c	10	Sikap	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	Sikap
70c0fc44-1e0b-49bc-89fa-b3e1772c3644	596b9232-d58b-4f11-83ca-5afe81fce60c	11	Inisiatif dan komunikasi	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
d3334d00-dfef-4914-b734-3c8de23972e7	596b9232-d58b-4f11-83ca-5afe81fce60c	12	Disiplin	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
96caee70-548b-4552-8c82-f93e40842bc8	596b9232-d58b-4f11-83ca-5afe81fce60c	13	Kejujuran	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
a9d0b8af-8b15-4b36-8db6-83628cde8c7d	596b9232-d58b-4f11-83ca-5afe81fce60c	14	Tanggung jawab	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
6a95bf2d-a427-4712-b5d3-6471b3717a9a	596b9232-d58b-4f11-83ca-5afe81fce60c	15	Sopan santun	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
f52a0eb1-2e6c-4e31-9bff-6e349ddea80b	ead3749e-9673-442a-b817-221df6d8e3c6	1	Pekerjaan	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	Pekerjaan
85a261bc-7f1f-40b5-bc7f-41042b34eed3	ead3749e-9673-442a-b817-221df6d8e3c6	2	Indikasi	0	8	6	8	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
5993947d-d554-439a-9d82-aeb572937012	ead3749e-9673-442a-b817-221df6d8e3c6	3	Preparasi	0	20	10	20	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
7a746166-d187-4596-b051-f84823ca71b4	ead3749e-9673-442a-b817-221df6d8e3c6	4	Isolasi daerah kerja	0	9	7	9	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
f9527bcb-f9c1-487b-b1d0-f01820697c75	ead3749e-9673-442a-b817-221df6d8e3c6	5	Pemasangan matriks	0	9	7	9	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
f7f57568-c3db-4d4a-b351-fbe24b783da5	ead3749e-9673-442a-b817-221df6d8e3c6	6	Liner, Etsa dan Bonding	0	36	20	36	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
cbf8684a-e8bb-41bc-b6d4-ab4dd67a9ace	ead3749e-9673-442a-b817-221df6d8e3c6	7	Penumpatan komposit	0	36	20	36	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
e8b6a089-01e8-4208-be8c-9566e240a5a8	ead3749e-9673-442a-b817-221df6d8e3c6	8	Finishing dan polishing	0	9	5	9	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
6b646e18-0a7c-455e-80db-585c70b92ece	ead3749e-9673-442a-b817-221df6d8e3c6	9	Kontrol	0	9	5	9	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
38a3425c-be31-462b-8b2e-2174283a866d	ead3749e-9673-442a-b817-221df6d8e3c6	10	Sikap	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	Sikap
1b2fc707-faea-4025-ad4e-887a8b51daab	ead3749e-9673-442a-b817-221df6d8e3c6	11	Inisiatif dan komunikasi	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
4958ab82-eefd-4593-b69a-572f8ef08002	ead3749e-9673-442a-b817-221df6d8e3c6	12	Disiplin	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
eec3ccb3-ccd8-4267-99bd-0f0b7802d9c3	ead3749e-9673-442a-b817-221df6d8e3c6	13	Kejujuran	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
aa4172e8-74da-491b-be2c-d73a2524ca39	ead3749e-9673-442a-b817-221df6d8e3c6	14	Tanggung jawab	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
68a7cc09-3d36-4475-b03d-c6f6906cdda3	ead3749e-9673-442a-b817-221df6d8e3c6	15	Sopan santun	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
5b359e63-25fc-4d41-b0bc-09007cc5048b	23cb5164-8204-44be-ba28-e39ffe2cdb1f	1	Pekerjaan	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	Pekerjaan
0e3b0bb3-55a8-452c-9d82-b6d1482aaa8d	23cb5164-8204-44be-ba28-e39ffe2cdb1f	2	Indikasi	0	10	6	10	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
f265c312-f909-411b-a168-323bbd880ce6	23cb5164-8204-44be-ba28-e39ffe2cdb1f	3	Preparasi	0	20	10	20	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
c18798e0-f869-40ff-a5ac-9cf962c71e9c	23cb5164-8204-44be-ba28-e39ffe2cdb1f	4	Isolasi daerah kerja	0	10	6	10	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
adb18ca1-3b47-4d4f-a129-5b0a86c956c2	23cb5164-8204-44be-ba28-e39ffe2cdb1f	5	Aplikasi Dentin Conditioner	0	10	7	10	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
70b07729-8d64-41a0-bf0a-b1718dbdcc0c	23cb5164-8204-44be-ba28-e39ffe2cdb1f	6	Penumpatan GIC/RMGIC	0	25	15	25	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
345f9246-6d54-4c35-a470-bab0fb58dea0	23cb5164-8204-44be-ba28-e39ffe2cdb1f	7	Pemolesan	0	15	10	15	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
be2f6245-9756-4fc7-961c-85226774f79b	23cb5164-8204-44be-ba28-e39ffe2cdb1f	8	Kontrol	0	10	6	10	0	0	0	1	\N	\N	0	0	0	1	Pekerjaan
181378d2-53ea-4382-acb0-b520f082c898	23cb5164-8204-44be-ba28-e39ffe2cdb1f	9	Sikap	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	Sikap
197a4c9b-fe61-4859-b9aa-530bb2be1d63	23cb5164-8204-44be-ba28-e39ffe2cdb1f	10	Inisiatif dan komunikasi	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
81b54585-713c-4ff7-997e-ea33d5d14882	23cb5164-8204-44be-ba28-e39ffe2cdb1f	11	Disiplin	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
f8738c1c-3929-4d95-877c-116028337d72	23cb5164-8204-44be-ba28-e39ffe2cdb1f	12	Kejujuran	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
4f94a4dd-68e6-48ca-a861-a5108856d11b	23cb5164-8204-44be-ba28-e39ffe2cdb1f	13	Tanggung jawab	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
db7ffddf-f314-438e-883c-8d5a9da822b9	23cb5164-8204-44be-ba28-e39ffe2cdb1f	14	Sopan santun	0	20	0	20	0	0	0	1	\N	\N	0	0	0	2	Sikap
4f5fea87-a314-4e82-a8ec-5690b36fc346	22a0e98a-a096-4bef-880b-e94e81429241	1	AKTIVITAS	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	AKTIVITAS
c76a9973-0063-4980-b7ca-1015fa531316	22a0e98a-a096-4bef-880b-e94e81429241	2	Persiapan peralatan\nAlat tulis\nLaporan pemeriksaan pasien	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	AKTIVITAS
2b38b658-0d26-489e-b1ca-fbcd68fa5de9	22a0e98a-a096-4bef-880b-e94e81429241	3	Persiapan operator\nPemasangan masker	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	AKTIVITAS
9d0c4274-0f34-4c31-a05b-86e0eedf61f7	22a0e98a-a096-4bef-880b-e94e81429241	4	Identitas pasien\nData diri pasien dan operator (mhs): nama px, umur px,\nTB-BB, pekerjaan, alamat, no telp/hp	4	0	0	0	0	0	0	1	\N	\N	0	2	0	1	AKTIVITAS
da02455a-ed49-49e5-b61e-457349177885	22a0e98a-a096-4bef-880b-e94e81429241	5	Keluhan utama	4	0	0	0	0	0	0	1	\N	\N	0	2	0	1	AKTIVITAS
f88f8360-01bc-4fcb-9f1b-25199cac244d	22a0e98a-a096-4bef-880b-e94e81429241	6	Riwayat kesehatan\nRiwayat penyakit, kelainan endokrin, penyakit pada masa\nanak-anak, alergi, kelainan saluran pernapasan tindakan\noperasi, sakit berat, kebiasaan buruk, sedang dalam\nperawatan dokter.	4	0	0	0	0	0	0	1	\N	\N	0	2	0	1	AKTIVITAS
9a399cdb-104e-42a3-a2cd-ceae5ae54b4e	22a0e98a-a096-4bef-880b-e94e81429241	7	Riwayat pertumbuhan dan perkembangan gigi	6	0	0	0	0	0	0	1	\N	\N	0	2	0	1	AKTIVITAS
0a126fba-c991-40b4-a4e8-0fdc5837ca81	22a0e98a-a096-4bef-880b-e94e81429241	8	Kebiasaan jelek yang berkaitan dengan keluhan pasien	6	0	0	0	0	0	0	1	\N	\N	0	2	0	1	AKTIVITAS
a35d8d94-9851-4930-8884-1df208133570	22a0e98a-a096-4bef-880b-e94e81429241	9	A. Menggunakan pertanyaan-pertanyaan yang sesuai\nuntuk mendapatkan informasi yang akurat dan\nadekuat	6	0	0	0	0	0	0	1	\N	\N	0	2	0	1	AKTIVITAS
72cd5f98-81af-4bb0-a78b-7ac0d628cded	22a0e98a-a096-4bef-880b-e94e81429241	10	B. Memberikan respon yang sesuai terhadap isyarat\npasien, baik secara verbal maupun nonverbal	4	0	0	0	0	0	0	1	\N	\N	0	2	0	1	AKTIVITAS
51b12f0c-ae40-496d-9ccb-bf229a01ff94	22a0e98a-a096-4bef-880b-e94e81429241	11	Sikap\nSantun terhadap pasien\nSantun terhadap instruktur\nDisiplin, tepat waktu	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	AKTIVITAS
2524772a-7b59-4c3b-945a-c951f93cf3f7	90ce231f-a7ab-4e48-9b4d-5823e8314175	1	AKTIVITAS	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	AKTIVITAS
0a8c97ba-49a5-485d-89a6-f6082b223746	90ce231f-a7ab-4e48-9b4d-5823e8314175	2	Persiapan peralatan dan bahan\nAlat: 2 kaca mulut, sonde, ekskavator, pinset, alat\nukur kepala	1	0	0	0	0	0	0	1	\N	\N	0	2	0	1	AKTIVITAS
18a301cb-f451-49d6-8e4d-1bdb8c4df21f	90ce231f-a7ab-4e48-9b4d-5823e8314175	3	Persiapan operator\nPemasangan masker terlebih dahulu kemudian\npemakaian sarung tangan	1	0	0	0	0	0	0	1	\N	2024-03-05 16:33:21	0	2	0	1	["kode_sub_name"]
06e6fb5a-cf8a-48d7-abef-b83388f6e642	90ce231f-a7ab-4e48-9b4d-5823e8314175	4	Pemeriksaan Ekstra Oral	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	Pemeriksaan Ekstra Oral
c5f6a876-160c-465a-a99e-b7dfd0626081	90ce231f-a7ab-4e48-9b4d-5823e8314175	5	Status gizi: TB, BB, indeks massa tubuh	1	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Pemeriksaan Ekstra Oral
d08f7ded-d1f1-4dca-80c6-6d7944a472a4	90ce231f-a7ab-4e48-9b4d-5823e8314175	6	Menentukan tipe kepala	2	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Pemeriksaan Ekstra Oral
90c8ba3f-fde1-4b3c-b9ca-15eda62f769f	90ce231f-a7ab-4e48-9b4d-5823e8314175	7	Menentukan tipe muka	2	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Pemeriksaan Ekstra Oral
ed9eb5ed-8d1f-4446-aa83-435ac5b867fd	90ce231f-a7ab-4e48-9b4d-5823e8314175	8	Menentukan tipe profil muka	1	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Pemeriksaan Ekstra Oral
36e87eeb-7a6b-47a7-a85f-8109c8752708	90ce231f-a7ab-4e48-9b4d-5823e8314175	9	Menentukan tonus bibir atas	1	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Pemeriksaan Ekstra Oral
e4d872eb-3a7f-4840-97d8-d3694fe82c4d	90ce231f-a7ab-4e48-9b4d-5823e8314175	10	Menentukan tonus bibir bawah	1	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Pemeriksaan Ekstra Oral
745fae5a-ce62-49ce-828e-3a7f9fe44f23	90ce231f-a7ab-4e48-9b4d-5823e8314175	11	Memeriksa posisi istirahat bibir	1	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Pemeriksaan Ekstra Oral
fd3dec47-a03f-46df-bb13-b112b12fe861	90ce231f-a7ab-4e48-9b4d-5823e8314175	12	Menentukan tonus mastikasi	1	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Pemeriksaan Ekstra Oral
3df7dcbd-4200-4aff-a44d-63595a1f678e	90ce231f-a7ab-4e48-9b4d-5823e8314175	13	Memeriksa sendi temporomandibular (TMJ)	2	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Pemeriksaan Ekstra Oral
17e85269-1ed4-41a8-8ab0-f2121e996de6	90ce231f-a7ab-4e48-9b4d-5823e8314175	14	Menentukan besarnya free way space	1	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Pemeriksaan Ekstra Oral
0d435bb7-c875-4957-aec0-8a28a36b5941	90ce231f-a7ab-4e48-9b4d-5823e8314175	14	Menentukan besarnya free way space	2	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Pemeriksaan Ekstra Oral
8aafae4c-7262-408e-b741-9e655f2193de	90ce231f-a7ab-4e48-9b4d-5823e8314175	15	Memeriksa path of closure	1	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Pemeriksaan Ekstra Oral
5bbba4b7-acd8-41ff-a86d-5f695ab489ae	90ce231f-a7ab-4e48-9b4d-5823e8314175	16	Memeriksa fonetik	1	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Pemeriksaan Ekstra Oral
02a1dc73-f44e-4300-89e0-bad60a70de60	90ce231f-a7ab-4e48-9b4d-5823e8314175	17	Pemeriksaan intra oral	0	0	0	0	0	0	0	1	\N	\N	0	0	3	3	Pemeriksaan intra oral
88b871c6-7b69-4886-8c4f-9a1705c27f77	90ce231f-a7ab-4e48-9b4d-5823e8314175	18	Memeriksa kebersihan mulut	2	0	0	0	0	0	0	1	\N	\N	0	2	0	3	Pemeriksaan intra oral
97635238-196f-4024-9159-a62963dff10c	90ce231f-a7ab-4e48-9b4d-5823e8314175	19	Memeriksa gingiva dan mukosa	2	0	0	0	0	0	0	1	\N	\N	0	2	0	3	Pemeriksaan intra oral
b4e3dde7-48e4-4e23-8fb9-1c6e8be5e181	90ce231f-a7ab-4e48-9b4d-5823e8314175	20	Memeriksa frenulum labii superior	2	0	0	0	0	0	0	1	\N	\N	0	2	0	3	Pemeriksaan intra oral
21e16a5b-44c1-4521-b9a9-5b0efa9e8611	90ce231f-a7ab-4e48-9b4d-5823e8314175	21	Memeriksa frenulum labii inferior	2	0	0	0	0	0	0	1	\N	\N	0	2	0	3	Pemeriksaan intra oral
2efbb583-153f-44b5-81dc-941dfb8c3a55	90ce231f-a7ab-4e48-9b4d-5823e8314175	22	Memeriksa frenulum lingualis	1	0	0	0	0	0	0	1	\N	\N	0	2	0	3	Pemeriksaan intra oral
2c20d576-77e5-417e-9a2a-653f8d8aba3e	90ce231f-a7ab-4e48-9b4d-5823e8314175	23	Memeriksa lingua / lidah	1	0	0	0	0	0	0	1	\N	\N	0	2	0	3	Pemeriksaan intra oral
9750e20c-74df-4ce8-b2b6-f3de68c38f39	90ce231f-a7ab-4e48-9b4d-5823e8314175	24	Memeriksa palatum	1	0	0	0	0	0	0	1	\N	\N	0	2	0	3	Pemeriksaan intra oral
bbbda967-d5aa-4f89-83cd-1cde44f8fbf0	90ce231f-a7ab-4e48-9b4d-5823e8314175	25	Memeriksa pola atrisi	1	0	0	0	0	0	0	1	\N	\N	0	2	0	3	Pemeriksaan intra oral
abf73b49-a777-4c07-b161-d9c8793b7b45	90ce231f-a7ab-4e48-9b4d-5823e8314175	26	Memeriksa keadaan gigi geligi	1	0	0	0	0	0	0	1	\N	\N	0	2	0	3	Pemeriksaan intra oral
de76cdd1-4cde-476e-85e2-9c4eaeee37f8	90ce231f-a7ab-4e48-9b4d-5823e8314175	26	Memeriksa keadaan gigi geligi	1	0	0	0	0	0	0	1	\N	\N	0	2	0	3	Pemeriksaan intra oral
465d6f95-d038-420c-a1eb-3dba5a18d23c	90ce231f-a7ab-4e48-9b4d-5823e8314175	26	Memeriksa keadaan gigi geligi	3	0	0	0	0	0	0	1	\N	2024-03-05 17:40:33	0	2	0	3	["kode_sub_name"]
b1289ee4-4dce-4730-838a-6e13e6b3342e	90ce231f-a7ab-4e48-9b4d-5823e8314175	27	Memeriksa garis tengah geligi atas	2	0	0	0	0	0	0	1	\N	\N	0	2	0	3	Pemeriksaan intra oral
7af9bb0f-01ea-45ce-8c78-111b7d0e37ac	90ce231f-a7ab-4e48-9b4d-5823e8314175	28	Memeriksa garis tengah geligi bawah	2	0	0	0	0	0	0	1	\N	\N	0	2	0	3	Pemeriksaan intra oral
224417e2-c5e4-4167-92fc-caa8bd166956	90ce231f-a7ab-4e48-9b4d-5823e8314175	29	Memeriksa tonsila	2	0	0	0	0	0	0	1	\N	\N	0	2	0	3	Pemeriksaan intra oral
4a472755-5467-4ba0-9f2b-5b8c680af6cc	90ce231f-a7ab-4e48-9b4d-5823e8314175	30	Sikap	2	0	0	0	0	0	0	1	\N	\N	0	2	0	3	Pemeriksaan intra oral
bdeeac41-4973-4919-934d-8ac83efe558f	5e362dfd-6121-4041-a98a-f21dd06441de	1	Persiapan	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	Persiapan
1ffbd8b6-8f9d-4bec-91f1-84ab694dc77c	5e362dfd-6121-4041-a98a-f21dd06441de	2	Persiapan alat dan bahan: sendok cetak berbagai ukuran,\nbowl, spatula, gelas takar, bahan cetak / alginat	1	0	0	0	0	0	0	1	\N	2024-03-05 17:48:34	0	2	0	1	["kode_sub_name"]
58f1ee6c-8a8b-4776-bac8-ad800d773eb9	5e362dfd-6121-4041-a98a-f21dd06441de	3	Persiapan operator: menggunakan lab jas, name tag,\nsarung tangan, dan masker	1	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Persiapan
a991088b-3e9e-4096-a162-65203d451790	5e362dfd-6121-4041-a98a-f21dd06441de	4	Persiapan pasien (lihat di buku panduan)	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Persiapan
0b870377-d283-482a-9957-ab40c87751db	5e362dfd-6121-4041-a98a-f21dd06441de	5	Pemilihan sendok cetak	1	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Persiapan
2f0a5063-a8b2-4b6c-8d34-9e68566f72d2	5e362dfd-6121-4041-a98a-f21dd06441de	6	Instruksi kepada pasien	1	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Persiapan
7fbc9063-7381-4ba3-bc18-ffd4d48d5fa5	5e362dfd-6121-4041-a98a-f21dd06441de	7	Prosedur mencetak rahang atas	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	Prosedur mencetak rahang atas
2db98abb-ea89-4e03-9f52-d95104237e97	5e362dfd-6121-4041-a98a-f21dd06441de	12	Menjelaskan kepada instruktur	2	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Prosedur mencetak rahang atas
52fee973-a2b5-445f-b003-1d44dfbd0d14	5e362dfd-6121-4041-a98a-f21dd06441de	10	Mencetak rahang atas (lihat di buku panduan)	2	0	0	0	0	0	0	1	\N	2024-03-05 17:56:22	0	2	0	2	["kode_sub_name"]
5d50bc25-1498-4e74-8f24-6d2ae88f1479	5e362dfd-6121-4041-a98a-f21dd06441de	9	Manipulasi bahan cetak	2	0	0	0	0	0	0	1	\N	2024-03-05 17:56:38	0	2	0	2	["kode_sub_name"]
e705604e-70f5-41fc-8895-d54d8368fde9	5e362dfd-6121-4041-a98a-f21dd06441de	11	Instruksi kepada pasien	1	0	0	0	0	0	0	1	\N	2024-03-05 17:57:59	0	2	0	2	["kode_sub_name"]
f8a6b1f8-cd90-43b6-9f99-4049611febd1	5e362dfd-6121-4041-a98a-f21dd06441de	8	Posisi operator	1	0	0	0	0	0	0	1	\N	2024-03-05 17:58:45	0	2	0	2	["kode_sub_name"]
2383e153-b8b8-4d92-9630-4311f73296cb	19633f89-3711-4827-9fc9-fdb49316e755	1	Indikasi dan Pengisian Status	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	Indikasi dan Pengisian Status
497b63d8-3b9e-4138-bf6f-a1a2b85e34ca	5e362dfd-6121-4041-a98a-f21dd06441de	13	Prosedur mencetak rahang bawah	0	0	0	0	0	0	0	1	\N	\N	0	0	3	3	Prosedur mencetak rahang bawah
30025f64-b9c4-4035-b3d5-124e1de879bd	5e362dfd-6121-4041-a98a-f21dd06441de	14	Posisi operator	1	0	0	0	0	0	0	1	\N	\N	0	2	0	3	Prosedur mencetak rahang bawah
5ad85993-9ce7-4f52-b615-3a8aa45c5f70	5e362dfd-6121-4041-a98a-f21dd06441de	15	Manipulasi bahan cetak	2	0	0	0	0	0	0	1	\N	\N	0	2	0	3	Prosedur mencetak rahang bawah
b49997e8-52a3-49ce-b776-a0e0a4c64794	5e362dfd-6121-4041-a98a-f21dd06441de	16	Mencetak rahang bawah (lihat di buku panduan)	2	0	0	0	0	0	0	1	\N	\N	0	2	0	3	Prosedur mencetak rahang bawah
44157942-afdd-435e-bfa3-a030ce98c089	5e362dfd-6121-4041-a98a-f21dd06441de	17	Instruksi kepada pasien	1	0	0	0	0	0	0	1	\N	\N	0	2	0	3	Prosedur mencetak rahang bawah
9bd37bac-47f1-438f-8831-5e53b5b13715	5e362dfd-6121-4041-a98a-f21dd06441de	18	Menjelaskan kepada instruktur	2	0	0	0	0	0	0	1	\N	\N	0	2	0	3	Prosedur mencetak rahang bawah
8066b580-4ba9-4386-8e2c-8e0ca7c193fc	48f68e47-a864-4aa8-89b7-b73faccd5f22	1	DISKUSI DAN PENULISAN MAKALAH	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	DISKUSI DAN PENULISAN MAKALAH
0d165e87-1609-47dc-bc3c-c864a9d6c6dc	5e362dfd-6121-4041-a98a-f21dd06441de	19	Menjelaskan kepada instruktur	0	0	0	0	0	0	0	1	\N	\N	0	0	4	4	Menjelaskan kepada instruktur
7ba38419-f03d-45af-8287-4b6d89e5475d	48f68e47-a864-4aa8-89b7-b73faccd5f22	1	a. kasus yang digunakan sesuai dengan requirement dan\nkompetensi	1	0	0	0	0	0	0	1	\N	\N	0	0	0	1	DISKUSI DAN PENULISAN MAKALAH
51446078-a74b-4feb-ad1f-3ba523fd710f	48f68e47-a864-4aa8-89b7-b73faccd5f22	2	a. kasus yang digunakan sesuai dengan requirement dan\nkompetensi	1	0	0	0	0	0	0	1	\N	\N	0	0	0	1	DISKUSI DAN PENULISAN MAKALAH
1824dc7c-c692-487e-b878-37cd13f93d44	5e362dfd-6121-4041-a98a-f21dd06441de	20	Hasil cetakan rahang atas	8	0	0	0	0	0	0	1	\N	\N	0	2	0	4	Menjelaskan kepada instruktur
a9c2a281-5662-4eeb-bc09-f06f40e8662f	48f68e47-a864-4aa8-89b7-b73faccd5f22	3	b. makalah disusun sesuai dengan kaidah penulisan	8	0	0	0	0	0	0	1	\N	\N	0	0	0	1	DISKUSI DAN PENULISAN MAKALAH
d51a6317-ef1c-4ef8-8af1-6ae558ae2961	15435521-7e66-45bb-9a29-1ed297ef1413	1	Melakukan persiapan awal	1	0	0	0	0	0	0	1	\N	\N	0	0	0	0	Melakukan persiapan awal
f6526707-943d-4894-a232-12e1fb7601c4	5e362dfd-6121-4041-a98a-f21dd06441de	22	Sikap terhadap instruktur selama perawatan berlangsung	2	0	0	0	0	0	0	1	\N	\N	0	2	0	4	Menjelaskan kepada instruktur
0ed211f7-7e77-48d1-ae7d-98a9f22dd35c	5e362dfd-6121-4041-a98a-f21dd06441de	21	Hasil cetakan rahang bawah	8	0	0	0	0	0	0	1	\N	2024-03-05 18:05:29	0	2	0	4	["kode_sub_name"]
b474d9fb-ee35-42b7-92e1-8cd28eec8418	60ddaea5-aec0-4965-9c76-00f0080a5790	1	Sub Total A	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	Sub Total A
d9698059-d09a-4c63-ade1-7f044b11a59f	60ddaea5-aec0-4965-9c76-00f0080a5790	2	Persiapan alat dan bahan\n‒ Persiapan bahan: model studi RA-RB, foto periapikal/\npanoramik jika diperlukan\n‒ Persiapan alat: jangka sorong, jangka, penggaris,\npensil, penghapus	1	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Sub Total A
76916aff-95cf-4a68-a214-af7bcf9fcf66	60ddaea5-aec0-4965-9c76-00f0080a5790	3	Persiapan operator\n‒ Operator menjelaskan kepada instruktur cara\npengukuran diskrepansi yang akan digunakan beserta\nalasannya	1	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Sub Total A
5051d933-2db5-47d8-a419-08cc70201bb1	60ddaea5-aec0-4965-9c76-00f0080a5790	4	Sub Total B	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	Sub Total B
4a82c555-a29d-48c4-9020-5c8bdada5eee	60ddaea5-aec0-4965-9c76-00f0080a5790	5	a. Mengukur tempat yang tersedia (available space)\nRA dan RB: mengukur dengan caliper atau jangka 6 segmen\n(M1 dan P2, P1 dan C, I2 dan I1 pada sisi kiri dan kanan).	2	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Sub Total B
176c3123-1cb9-4941-b84b-f5a7867cc44a	60ddaea5-aec0-4965-9c76-00f0080a5790	6	b. Mengukur tempat yang dibutuhkan (required space)\nMengukur dan menjumlahkan lebar mesio-distal 6 segmen\ngigi (M1 dan P2, P1 dan C, I2 dan I1 pada sisi kiri dan kanan)	2	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Sub Total B
f6241b71-ea0e-4571-a188-b3c98a71923e	60ddaea5-aec0-4965-9c76-00f0080a5790	7	c. Diskrepansi\nDiskrepansi setiap segmen (6): tempat yang tersedia -\ntempat yang dibutuhkan\nMenjumlah diskrepansi 6 segmen	2	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Sub Total B
f575de00-42ed-41e1-b680-5744db90d135	60ddaea5-aec0-4965-9c76-00f0080a5790	8	Menjelaskan kepada instruktur\nMahasiswa mampu menganalisis dan menjelaskan hasil\npenghitungan diskrepansi kepada instruktur	4	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Sub Total B
5d0852f3-56b8-49aa-8681-411ffe25d5c7	3b025e64-cedc-4ac2-b2ec-8f44ba46e89a	1	Aktivitas	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	Aktivitas
25f6de31-e5b9-4c08-b68e-60e55fc1adfe	3b025e64-cedc-4ac2-b2ec-8f44ba46e89a	2	Persiapan alat dan bahan\n‒ Alat: viewer, kertas kalkir, pensil, penghapus,\npenggaris dan busur derajat\n‒ Bahan: sefalogram	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
478434fb-e9f2-45c7-86bf-a4726482ea1e	3b025e64-cedc-4ac2-b2ec-8f44ba46e89a	3	Melakukan tracing sefalogram pada kertas kalkir	7	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
ed621c6d-707b-4dea-a9a1-b97b8cba8753	3b025e64-cedc-4ac2-b2ec-8f44ba46e89a	4	Menentukan titik-titik orientasi analisis sefalometri\nmetode Steiner	6	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
fdf4d5f4-9cba-47ac-9c0d-315ccfb1de1e	3b025e64-cedc-4ac2-b2ec-8f44ba46e89a	5	Menentukan garis-garis orientasi pada analisis sefalometri\nmetode Steiner	6	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
7b12f049-7efc-4d74-97f8-40dc74f9b517	3b025e64-cedc-4ac2-b2ec-8f44ba46e89a	6	Menentukan sudut-sudut orientasi pada analisis\nsefalometri metode Steiner	6	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
cc85dcc1-9a1a-4e37-9e44-eff3dd356da2	3b025e64-cedc-4ac2-b2ec-8f44ba46e89a	7	Menjelaskan interpretasi sudut-sudut orientasi pada\nanalisis sefalometri metode Steiner	6	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
a20bf6f0-5ddd-4b45-acf6-ad7521450998	3b025e64-cedc-4ac2-b2ec-8f44ba46e89a	8	Menjelaskan diagnosis berdasarkan analisis sefalometri\nmetode Steiner	7	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
90668a91-f8a8-4525-b170-a872f0290bab	2d589f54-d525-4de1-bf7a-92dddda02e4c	1	Foto Wajah	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	Foto Wajah
b9962cfa-da63-4cba-9f9c-4da023da4865	2d589f54-d525-4de1-bf7a-92dddda02e4c	2	Tampak depan tanpa senyum	4	0	0	0	0	0	0	1	\N	2024-03-05 18:58:31	0	2	0	1	["kode_sub_name"]
2517432d-caa9-46f3-9fc5-b9d3f52a80ec	2d589f54-d525-4de1-bf7a-92dddda02e4c	3	Tampak depan senyum gigi terlihat	4	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Foto Wajah
10c8b9b2-a021-45e4-93f6-4140429ca167	2d589f54-d525-4de1-bf7a-92dddda02e4c	4	Tampak samping profil	4	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Foto Wajah
ea6e1e8b-774f-48f8-8911-7a9e0d94ad00	2d589f54-d525-4de1-bf7a-92dddda02e4c	5	Tampak oblique kanan	4	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Foto Wajah
e1f6161c-9f6b-4e17-ba7c-d8c1a28da4db	2d589f54-d525-4de1-bf7a-92dddda02e4c	6	Tampak oblique kiri	4	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Foto Wajah
c3b96699-a299-4b02-a919-736693bc5c29	2d589f54-d525-4de1-bf7a-92dddda02e4c	7	Foto Gigi	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	Foto Gigi
071e0c08-1e3f-4e0d-af40-ebb1da894836	2d589f54-d525-4de1-bf7a-92dddda02e4c	8	Tampak depan	4	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Foto Gigi
5a262150-7820-422f-9a60-174098b2f958	2d589f54-d525-4de1-bf7a-92dddda02e4c	10	Tampak samping kiri	4	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Foto Gigi
62e5f922-9a6d-4ffb-ad9d-8c8fc11600d1	2d589f54-d525-4de1-bf7a-92dddda02e4c	11	Tampak oklusal atas	4	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Foto Gigi
be6ecb86-7aa3-4e38-b4a9-1dd7e20e764e	2d589f54-d525-4de1-bf7a-92dddda02e4c	12	Tampak oklusal bawah	4	0	0	0	0	0	0	1	\N	\N	0	2	0	2	Foto Gigi
81872a92-496a-403c-94a3-92a21c7fa04f	2feb22f2-f122-4cf2-9ada-6238d4369a18	1	AKTIVITAS	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	AKTIVITAS
0e7e3f96-8b2e-4a2b-94df-7e590f492a25	2feb22f2-f122-4cf2-9ada-6238d4369a18	2	Diagnosis	3	0	0	0	0	0	0	1	\N	\N	0	2	0	1	AKTIVITAS
f7e75882-2999-4371-8340-d19b6e7ea03f	2feb22f2-f122-4cf2-9ada-6238d4369a18	3	Etiologi	3	0	0	0	0	0	0	1	\N	\N	0	2	0	1	AKTIVITAS
8ed14f4b-0fce-4f34-bbc0-0bdefd299dfe	2feb22f2-f122-4cf2-9ada-6238d4369a18	4	Menentukan rujukan ke departemen lain untuk\nperawatan pre-ortodonti	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	AKTIVITAS
abc44806-8529-48da-9f91-a1238efb83cc	2feb22f2-f122-4cf2-9ada-6238d4369a18	5	RA	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	RA
83e66970-ebab-4785-b008-c3a585de0847	2feb22f2-f122-4cf2-9ada-6238d4369a18	6	RB	0	0	0	0	0	0	0	1	\N	\N	0	0	3	3	RB
1874c32e-f5ab-4e46-a12e-57dc77c9decb	2feb22f2-f122-4cf2-9ada-6238d4369a18	7	Menentukan rencana pencarian ruang, koreksi\nmalposisi gigi individual, occlusal adjustment dan\nretensi	4	0	0	0	0	0	0	1	\N	\N	0	2	0	2	RA
c83671ee-1072-435f-826a-47c22d8070cd	2feb22f2-f122-4cf2-9ada-6238d4369a18	8	Menentukan rencana pencarian ruang, koreksi\nmalposisi gigi individual, occlusal adjustment dan\nretensi	4	0	0	0	0	0	0	1	\N	\N	0	2	0	3	RB
230a4ba3-3667-4e24-8035-17cf9669d2c7	2feb22f2-f122-4cf2-9ada-6238d4369a18	9	Menentukan komponen aktif yang digunakan	4	0	0	0	0	0	0	1	\N	\N	0	2	0	2	RA
7ba2e647-17e0-407c-ba07-f6285089b8d4	2feb22f2-f122-4cf2-9ada-6238d4369a18	10	Menentukan komponen aktif yang digunakan	4	0	0	0	0	0	0	1	\N	\N	0	2	0	3	RB
64cce734-113a-4364-bf2c-135e4a6096d5	2feb22f2-f122-4cf2-9ada-6238d4369a18	11	Menentukan komponen aktif yang digunakan	2	0	0	0	0	0	0	1	\N	\N	0	2	0	2	RA
5d986557-5687-47ca-b197-9236ee242ae3	2feb22f2-f122-4cf2-9ada-6238d4369a18	12	Menentukan komponen aktif yang digunakan	2	0	0	0	0	0	0	1	\N	\N	0	2	0	3	RB
f30a9064-6d5b-43ac-9f4b-e038872934ba	2feb22f2-f122-4cf2-9ada-6238d4369a18	13	Menentukan cengkeram retensi yang digunakan	2	0	0	0	0	0	0	1	\N	\N	0	2	0	2	RA
887adda2-e502-491b-8274-11446b02228a	2feb22f2-f122-4cf2-9ada-6238d4369a18	14	Menentukan cengkeram retensi yang digunakan	2	0	0	0	0	0	0	1	\N	\N	0	2	0	3	RB
ec9de5bf-e7ed-464b-9690-7dcb093e1d59	2feb22f2-f122-4cf2-9ada-6238d4369a18	15	Menentukan desain basis akrilik	2	0	0	0	0	0	0	1	\N	\N	0	2	0	2	RA
239a3c5f-24e1-4d5e-8d5f-3a63eb272ea7	2feb22f2-f122-4cf2-9ada-6238d4369a18	16	Menentukan desain basis akrilik	2	0	0	0	0	0	0	1	\N	\N	0	2	0	3	RB
cc4efdc7-85c0-4948-9d5a-a0ce9a04ee51	2feb22f2-f122-4cf2-9ada-6238d4369a18	17	Menggambar desain alat lepasan di model kerja	2	0	0	0	0	0	0	1	\N	\N	0	2	0	2	RA
b2c062be-f857-4dc7-b428-b60e4bebdb7f	2feb22f2-f122-4cf2-9ada-6238d4369a18	18	Menggambar desain alat lepasan di model kerja	2	0	0	0	0	0	0	1	\N	\N	0	2	0	3	RB
6a594806-8b9e-4be1-ac40-fd8608ef7e96	c1ff27fa-7779-4167-ba79-b55253758f95	1	Tahapan	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	Tahapan
82498fde-8f38-4f50-9c1b-6d5f13c194f1	c1ff27fa-7779-4167-ba79-b55253758f95	2	Mempersiapkan alat diagnostic standard, rekam medik, dan\nmodel	1	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Tahapan
8f49e129-5247-476f-97b3-edeffe1da8ed	c1ff27fa-7779-4167-ba79-b55253758f95	3	Mempersiapkan pasien di dental unit	1	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Tahapan
5b0ef975-708f-481e-afec-281ecbb0fd7b	c1ff27fa-7779-4167-ba79-b55253758f95	4	Menggunakan sarung tangan dan masker	1	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Tahapan
bf1843e6-ad09-499e-8cd4-8c4ad52a8de1	c1ff27fa-7779-4167-ba79-b55253758f95	5	Menjelaskan kepada pasien mengenai tindakan yang akan\ndilakukan	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Tahapan
8da13bde-95bf-48fc-9f2a-006bcb35abda	c1ff27fa-7779-4167-ba79-b55253758f95	6	Menunjukkan alat ortodontik lepasan yang siap diinsersi\nkepada instruktur	1	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Tahapan
c90f40cd-1ad5-4882-86cd-26cb88cb8d4f	c1ff27fa-7779-4167-ba79-b55253758f95	7	Menjelaskan dan menjawab pertanyaan yang diberikan\ninstruktur tentang hal yang berhubungan dengan insersi	4	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Tahapan
88d1a97a-5a63-4ad1-94c2-2edac74a7236	c1ff27fa-7779-4167-ba79-b55253758f95	8	Menginsersikan alat ortodontik lepasan di depan instruktur\na. Rahang atas	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Tahapan
0d8e9db3-526f-4e9b-9dae-bcbb1bc500e5	c1ff27fa-7779-4167-ba79-b55253758f95	9	Menginsersikan alat ortodontik lepasan di depan instruktur\na. Rahang bawah	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Tahapan
052b1111-1ccd-4cb3-8d2f-c0caf63d4e65	c1ff27fa-7779-4167-ba79-b55253758f95	10	Ketepatan dan menyesuaikan posisi letak komponen aktif,\npasif, retentif di dalam mulut\na. Rahang atas	10	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Tahapan
9733c6f0-bb87-4f7f-9683-62d12882b802	c1ff27fa-7779-4167-ba79-b55253758f95	11	Ketepatan dan menyesuaikan posisi letak komponen aktif,\npasif, retentif di dalam mulut\nb. Rahang bawah	10	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Tahapan
19b7fef4-0216-46a7-9858-2cf9d720d027	c1ff27fa-7779-4167-ba79-b55253758f95	11	Ketepatan dan menyesuaikan posisi letak komponen aktif,\npasif, retentif di dalam mulut\nb. Rahang bawah	10	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Tahapan
306ba922-c37e-4821-9b91-e8a830f5cf2f	c1ff27fa-7779-4167-ba79-b55253758f95	12	Menjelaskan dan memberi instruksi kepada pasien\nmengenai alat yang telah dipakai (cara memasang dan\nmelepas, cara perawatan, dll)	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Tahapan
625bba16-ca81-40f6-a333-824995d152f4	c1ff27fa-7779-4167-ba79-b55253758f95	13	Sikap terhadap pasien selama perawatan berlangsung	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Tahapan
50a6aad7-30c7-4952-b01d-dfaeeca8a8b7	c1ff27fa-7779-4167-ba79-b55253758f95	14	Sikap terhadap instruktur selama\nperawatan berlangsung	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Tahapan
1b7645e5-739e-4d6e-9a98-27e9dbe6d6d6	352f12bb-e8b9-4986-83cd-bfc882379632	1	Aktivitas	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	Aktivitas
29435dc8-4f2b-4450-bbce-fe38ed48924d	352f12bb-e8b9-4986-83cd-bfc882379632	2	Mempersiapkan alat diagnostik standard, rekam medik, dan\nmodel, alat aktivasi	1	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
edf45011-9872-42ba-ae33-25c5e4915a8c	352f12bb-e8b9-4986-83cd-bfc882379632	3	Mempersiapkan pasien di dental unit	1	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
17e05e42-5f97-44d9-a061-f8ee58eb75e3	352f12bb-e8b9-4986-83cd-bfc882379632	4	Menggunakan sarung tangan dan masker	1	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
e62d524a-c821-47c7-8894-2907feea044b	352f12bb-e8b9-4986-83cd-bfc882379632	5	Menjelaskan kepada pasien mengenai tindakan yang\nakan dilakukan	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
dde1956c-d5d4-4481-92af-b5ec49c28ebf	352f12bb-e8b9-4986-83cd-bfc882379632	6	Menunjukkan pasien kepada instruktur sebelum alat\nortodontik lepasan diaktivasi (alat terpasang pada pasien)	1	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
18058000-459e-49f6-abc3-03fee8b14c6e	352f12bb-e8b9-4986-83cd-bfc882379632	7	Menjelaskan dan menjawab pertanyaan yang diberikan\ninstruktur tentang hal yang berhubungan dengan cara\naktivasi dan pergerakan gigi	5	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
d8de084a-1511-4285-9a7f-16fe85cfc78c	352f12bb-e8b9-4986-83cd-bfc882379632	8	Melakukan aktivasi komponen aktif di depan instruktur\na. Rahang atas	3	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
284da12b-3d3f-4740-8d1d-0f3e9c002032	352f12bb-e8b9-4986-83cd-bfc882379632	7	Melakukan aktivasi komponen aktif di depan instruktur\nb. Rahang bawah	3	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
df53544a-eb71-4cfa-bdba-4196f55f71b9	352f12bb-e8b9-4986-83cd-bfc882379632	10	Menginsersikan alat yang telah diaktivasi di depan\ninstruktur\na. Rahang atas	3	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
79e2796e-0db7-4a02-a6cd-e957beb12a44	352f12bb-e8b9-4986-83cd-bfc882379632	11	Menginsersikan alat yang telah diaktivasi di depan\ninstruktur\nb. Rahang bawah	3	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
cea38bbc-5e51-4e5f-b80f-9184a7db7d52	352f12bb-e8b9-4986-83cd-bfc882379632	12	Ketepatan dan penyesuaian letak komponen aktif, pasif,\nretentif di dalam mulut\na. Rahang atas	6	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
17816e9c-1a93-44c2-8680-893ea55409e0	352f12bb-e8b9-4986-83cd-bfc882379632	13	Ketepatan dan penyesuaian letak komponen aktif, pasif,\nretentif di dalam mulut\nb. Rahang bawah	6	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
ea9d207c-adb6-468e-8238-8011f0b8272a	352f12bb-e8b9-4986-83cd-bfc882379632	14	Menjelaskan dan memberi instruksi kepada pasien\nmengenai alat yang telah dipakai (cara memasang dan\nmelepas, perawatan, cara aktivasi jika memakai skrup\nexpansi, dll)	3	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
345514da-9d65-44aa-a83c-c8542f6ce89b	352f12bb-e8b9-4986-83cd-bfc882379632	15	Sikap terhadap pasien selama perawatan berlangsung	1	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
6765d4a7-1775-41df-a8a8-db6f7de6869b	352f12bb-e8b9-4986-83cd-bfc882379632	16	Sikap terhadap instruktur selama perawatan berlangsung	1	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Aktivitas
3f8c9b5a-1b5a-4c28-b2f7-34a5df25b5e2	832939f0-0ace-4fd3-89aa-e659550f041e	1	Kontrol	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	Kontrol
8148a45f-cb63-4dae-a3f1-348690cc9b9e	832939f0-0ace-4fd3-89aa-e659550f041e	2	Kontrol 1	80	0	0	0	0	0	0	1	\N	\N	0	80	0	1	Kontrol
3647b343-89ff-4308-88b7-d585f66d7fc4	832939f0-0ace-4fd3-89aa-e659550f041e	3	Kontrol 2	80	0	0	0	0	0	0	1	\N	\N	0	80	0	1	Kontrol
74a809ee-2cbd-417c-96bc-31beaaf32dbd	832939f0-0ace-4fd3-89aa-e659550f041e	4	Kontrol 3	80	0	0	0	0	0	0	1	\N	\N	0	80	0	1	Kontrol
eb201b29-d6d6-403f-b03b-d0ab871fb597	5f1bf278-5507-418a-8def-8d9f0c5709d8	1	Deskripsi	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	Deskripsi
807a64f8-626b-46be-b20d-955ae5216a3d	5f1bf278-5507-418a-8def-8d9f0c5709d8	2	Keserasian basis segi 7 dengan lengkung\ngigi	10	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Deskripsi
2c92df75-2ce9-4025-88f5-7d997b1f5f10	5f1bf278-5507-418a-8def-8d9f0c5709d8	3	Basis rahang atas dan rahang bawah\nsejajar	12	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Deskripsi
8817183e-125a-447e-bc70-a528534252f8	5f1bf278-5507-418a-8def-8d9f0c5709d8	4	Dapat berdiri rapat pada setiap sisi	10	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Deskripsi
07a92aa7-a9eb-4437-b37e-4abd33e3b2d3	5f1bf278-5507-418a-8def-8d9f0c5709d8	5	Kehalusan model studi	8	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Deskripsi
ec44f7e4-9462-4bcc-8788-51e4fe622652	a5cb8841-1d03-4102-918f-5a8b7e3456fd	1	Deskripsi	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	Deskripsi
d2c20cea-8d6b-483a-9610-bf2689f811c8	a5cb8841-1d03-4102-918f-5a8b7e3456fd	2	Anamnesis (yang lama)	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Deskripsi
abc942ca-68bd-4a2e-a4b0-053a863256d7	a5cb8841-1d03-4102-918f-5a8b7e3456fd	3	Pemeriksaan EO dan IO (lama)	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Deskripsi
40be6b60-40d8-4969-8c0a-fb302c0debc1	a5cb8841-1d03-4102-918f-5a8b7e3456fd	4	Analisis model	4	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Deskripsi
49b1415c-7965-48e1-81f3-898c13251610	a5cb8841-1d03-4102-918f-5a8b7e3456fd	5	Foto pasien extra dan intra oral (lama dan baru)	4	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Deskripsi
ee509a0f-33b1-46cc-87c4-a7199d856ca4	a5cb8841-1d03-4102-918f-5a8b7e3456fd	6	Diagnosis (lama)	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Deskripsi
767624d5-14df-4786-b875-27516c4bf26c	a5cb8841-1d03-4102-918f-5a8b7e3456fd	7	Rencana perawatan (lama)	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Deskripsi
fe91bf22-ebc4-4fbd-a280-431ce2555039	a5cb8841-1d03-4102-918f-5a8b7e3456fd	8	Hasil perawatan	4	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Deskripsi
798ff61d-b04b-41be-b27f-6e598248a059	a5cb8841-1d03-4102-918f-5a8b7e3456fd	9	Kemampuan menjawab dan diskusi	5	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Deskripsi
92fe64c3-9c68-4f94-8963-67cc52dcbd39	a5cb8841-1d03-4102-918f-5a8b7e3456fd	10	Presentasi	4	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Deskripsi
dc7ef603-04b6-4108-999b-d41a1abb3651	a5cb8841-1d03-4102-918f-5a8b7e3456fd	11	Penulisan	4	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Deskripsi
6e177f82-1ffd-4010-a61a-a93349984fa6	a5cb8841-1d03-4102-918f-5a8b7e3456fd	12	Model studi (lama dan baru)	4	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Deskripsi
208351e1-6fbe-462f-98b2-28b2634b7fec	a5cb8841-1d03-4102-918f-5a8b7e3456fd	13	Sikap	3	0	0	0	0	0	0	1	\N	\N	0	2	0	1	Deskripsi
4bc92422-a724-47bd-9053-6da6280286fb	0bb1d8ea-3074-42bb-af7b-cb40db0e62f2	1	Perubahan sesuai rencana perawatan	0	0	0	0	0	0	0	1	\N	\N	0	0	0	0	Perubahan sesuai rencana perawatan
bbec7ff7-22df-4a5d-b903-80a774dcd605	0bb1d8ea-3074-42bb-af7b-cb40db0e62f2	2	Sedikit perubahan	0	0	0	0	0	0	0	1	\N	\N	0	0	0	0	Perubahan sesuai rencana perawatan
ab544026-bb40-45cd-a20b-a749e0700ac6	0bb1d8ea-3074-42bb-af7b-cb40db0e62f2	3	Tidak ada perubahan	0	0	0	0	0	0	0	1	\N	\N	0	0	0	0	Perubahan sesuai rencana perawatan
e2401f80-1291-4eef-abc1-7e371ef44fb0	0bb1d8ea-3074-42bb-af7b-cb40db0e62f2	4	Menjadi lebih buruk	0	0	0	0	0	0	0	1	\N	\N	0	0	0	0	Perubahan sesuai rencana perawatan
1aec6f4f-382a-4e11-b52a-64536ab6c70f	36da7989-cedc-49c4-82e1-aabead99a6c2	9	Posisi kerja operator ergonomis. Pencahayaan, arah pandang, retraksi lidah- mukosa-bibir sesuai daerah kerja	6	0	0	0	0	0	0	1	\N	\N	0	2	0	2	PERAWATAN SKELING MANUAL - SKELING MANUAL
4e55c610-f1ad-4d1b-8cb0-1c06e83c8786	36da7989-cedc-49c4-82e1-aabead99a6c2	7	Alat: kaca mulut, sonde halfmoon, pinset, probe periodontal, skaler manual (Sickle, Hoe, Chisel), brush/rubber cup. Bahan: pasta profilkasis, pumis, hidrogen peroksida (H2O2 3 %)/povidone iodin 1%, aquabidest, tampon, cotton roll, cotton pellet, siring irigasi.	1	0	0	0	0	0	0	1	\N	2024-03-06 11:19:22	0	2	0	2	PERAWATAN SKELING MANUAL - SKELING MANUAL
d8ca132b-cedc-43c8-96d8-f96520f23c8a	36da7989-cedc-49c4-82e1-aabead99a6c2	10	Penggunaan skeler: stabilisasi instrumen (tumpuan dan sandaran jari sesuai regio), adaptasi, angulasi (450), tekanan lateral, arah gerakan (horizontal, oblique dan vertikal) pada sisi kerja, berkontak dengan gigi	9	0	0	0	0	0	0	1	\N	\N	0	2	0	2	PERAWATAN SKELING MANUAL - SKELING MANUAL
dbd944c7-1a89-4b51-8957-58cc77004e61	36da7989-cedc-49c4-82e1-aabead99a6c2	8	Skor terisi lengkap dan benar: Indeks plak, Indeks kalkulus, bleeding on probing (BOP), menginstruksikan pasien kumur antiseptik	2	0	0	0	0	0	0	1	\N	\N	0	2	0	2	PERAWATAN SKELING MANUAL - SKELING MANUAL
12fc6561-fe2f-48cc-a98f-9e15001a473c	36da7989-cedc-49c4-82e1-aabead99a6c2	2	Diagnosis Kerja (nilai 2= sesuai dengan hasil pemeriksaan, nilai< 2= kurang\nsesuai hasil pemeriksaan)	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	PERAWATAN SKELING MANUAL - PENGISIAN STATUS (ANAMNESIS DAN PEMERIKSAAN LENGKAP)
f4d45031-0e77-4dab-854e-4e1687a933d5	36da7989-cedc-49c4-82e1-aabead99a6c2	5	Penyelesaian (data rekam medik dan diskusi diselesaikan di hari yang sama (nilai 2), 2 hari setelah kerja (nilai 1), > 2 hari kerja (nilai < 1))	1	0	0	0	0	0	0	1	\N	2024-03-06 11:18:24	0	2	0	1	PERAWATAN SKELING MANUAL - PENGISIAN STATUS (ANAMNESIS DAN PEMERIKSAAN LENGKAP)
4a8119ee-ef0a-4c57-84bf-56ac116fafc9	36da7989-cedc-49c4-82e1-aabead99a6c2	3	Rencana Perawatan (nilai 2= sesuai dengan terapi periodontal suportif, nilai < 2= kurang sesuai)	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	PERAWATAN SKELING MANUAL - PENGISIAN STATUS (ANAMNESIS DAN PEMERIKSAAN LENGKAP)
5cd76271-7139-48f0-9f57-8796250190bf	36da7989-cedc-49c4-82e1-aabead99a6c2	4	Prognosis (nilai 2= sesuai dengan hasil pemeriksaan, nilai < 2= kurang sesuai)	1	0	0	0	0	0	0	1	\N	2024-03-06 11:18:28	0	2	0	1	PERAWATAN SKELING MANUAL - PENGISIAN STATUS (ANAMNESIS DAN PEMERIKSAAN LENGKAP)
46c34045-01a8-4f41-9c1f-2f2bbb71d396	36da7989-cedc-49c4-82e1-aabead99a6c2	1	Pemeriksaan (pengisian data pasien, keluhan utama, anemnesis, pemeriksaan EO, IO dan radiografis)	1	0	0	0	0	0	0	1	\N	2024-03-06 11:18:40	0	2	0	1	PERAWATAN SKELING MANUAL - PENGISIAN STATUS (ANAMNESIS DAN PEMERIKSAAN LENGKAP)
a6268a58-1a7b-482e-9f51-0a84cfe9f8d9	36da7989-cedc-49c4-82e1-aabead99a6c2	6	Persiapan awal: kriteria pasien poket ≤ 3 mm, kalkulus kelas 1 (supragingiva) atau kalkulus kelas 2 (subgingiva); pasien bersedia dirawat, menandatangani informed consent	1	0	0	0	0	0	0	1	\N	2024-03-06 11:19:18	0	2	0	2	PERAWATAN SKELING MANUAL - SKELING MANUAL
12c9e67f-0125-478a-8dc8-0010f1c4ed62	36da7989-cedc-49c4-82e1-aabead99a6c2	11	Kontrol perdarahan: Irigasi H2O2 3% (BOP > 2), kemudian irigasi dengan aquabidest. Aplikasi pasta profilaksis/pumis, aplikasi pada gigi dengan brush/rubber cup (BOP < 2)	8	0	0	0	0	0	0	1	\N	\N	0	2	0	2	PERAWATAN SKELING MANUAL - SKELING MANUAL
4314ce0c-e122-44fe-807b-00c5bbdb196a	2569196c-7dfd-4ab3-9845-0cc1fe7fc1e9	7	Santun terhadap dosen	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
ac293356-dfad-487a-ad0a-66e06341efd3	36da7989-cedc-49c4-82e1-aabead99a6c2	12	Evaluasi: setelah dilakukan scaling, tidak ditemukan kalkulus, stain dan plak baik supragingiva dan subgingiva	3	0	0	0	0	0	0	1	\N	\N	0	3	0	2	PERAWATAN SKELING MANUAL - SKELING MANUAL
fbcec4fc-0f0c-4b2d-86dc-ba358c885baa	36da7989-cedc-49c4-82e1-aabead99a6c2	13	Instruksi pasien: kontrol 7 hari kemudian, pemeliharaan kesehatan gigi dan mulut di rumah	3	0	0	0	0	0	0	1	\N	\N	0	3	0	2	PERAWATAN SKELING MANUAL - SKELING MANUAL
edbb3b8c-26ba-4d4b-b47c-da0a2b640f60	36da7989-cedc-49c4-82e1-aabead99a6c2	1	Kunjungan I (Saat skeling)	0	60-80	60	80	0-80	0	80	1	\N	\N	0	0	0	3	PLAK KONTROL SKELING MANUAL
67027213-6a16-4434-88d3-852240568417	36da7989-cedc-49c4-82e1-aabead99a6c2	2	Kunjungan II (Kontrol I)	0	60-80	60	80	0-80	0	80	1	\N	\N	0	0	0	3	PLAK KONTROL SKELING MANUAL
77a9fe42-410a-4e42-b6aa-73be5549933a	36da7989-cedc-49c4-82e1-aabead99a6c2	3	Kunjungan III (Kontrol II)	0	60-80	60	80	0-80	0	80	1	\N	\N	0	0	0	3	PLAK KONTROL SKELING MANUAL
519f2d87-ede2-47fa-98f2-defab532bff3	36e976a1-7b53-4d82-a025-72c3de4e1ed9	0	PEKERJAAN KLINIK	0	0	0	0	0	0	0	1	\N	2024-04-01 09:52:53	0	0	1	1	["kode_sub_name"]
e4179566-439c-4d6e-b7a2-d1a32228978e	36e976a1-7b53-4d82-a025-72c3de4e1ed9	1	Informed Consent	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	["kode_sub_name"]
89382123-38f6-4e90-9526-30c7973bf572	36e976a1-7b53-4d82-a025-72c3de4e1ed9	2	Proteksi Radiasi	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	["kode_sub_name"]
77ebd490-e367-4058-be7f-09eac021c473	36e976a1-7b53-4d82-a025-72c3de4e1ed9	3	Posisi Pasien	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	["kode_sub_name"]
ff6078d5-3b54-4bbd-a00d-cc66d3d1e259	36e976a1-7b53-4d82-a025-72c3de4e1ed9	4	Posisi Film	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	["kode_sub_name"]
b5280e46-b162-4b9e-bfd0-2f7ab634e077	36e976a1-7b53-4d82-a025-72c3de4e1ed9	5	Posisi Tabung Xray	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	["kode_sub_name"]
650d44b1-6c10-4a94-abf0-21702d538d39	36e976a1-7b53-4d82-a025-72c3de4e1ed9	6	Instruksi Pasien	10	0	0	0	0	0	0	1	\N	\N	0	10	0	1	["kode_sub_name"]
31d76d93-460c-4c22-8dc9-8ddac3055bd5	36e976a1-7b53-4d82-a025-72c3de4e1ed9	7	Exposure	10	0	0	0	0	0	0	1	\N	\N	0	10	0	1	["kode_sub_name"]
7644b9f2-1729-40eb-a6c5-abe2545a4555	36e976a1-7b53-4d82-a025-72c3de4e1ed9	0	SIKAP	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	SIKAP
d3bbda49-4696-419d-a770-9e3e9e1bf01d	36e976a1-7b53-4d82-a025-72c3de4e1ed9	1	Inisiatif	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
80a50b4b-28b6-4c24-b1dd-38d04e446437	36e976a1-7b53-4d82-a025-72c3de4e1ed9	2	Disiplin	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
823d56f5-8d50-4ce0-98e1-a6c3eedc143a	36e976a1-7b53-4d82-a025-72c3de4e1ed9	3	Kejujuran	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
9e32d68a-0eb2-48c1-bc52-4a39d4f0d018	36e976a1-7b53-4d82-a025-72c3de4e1ed9	4	Tanggung Jawab	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
ed11558f-8782-44bc-86df-68eced45d5e7	36e976a1-7b53-4d82-a025-72c3de4e1ed9	5	Kerjasama	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
95e9b0c0-f682-470b-95fe-69472cd7a1a9	36e976a1-7b53-4d82-a025-72c3de4e1ed9	6	Santun terhadap pasien	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
828a05e8-09ca-404e-ad19-37ea6cf19295	36e976a1-7b53-4d82-a025-72c3de4e1ed9	7	Santun terhadap dosen	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
599152ae-139e-4752-8449-bffbcd9d0bec	16e7fcab-101f-498c-8989-062ec832c8b8	0	PEKERJAAN KLINIK	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	PEKERJAAN KLINIK
d4201e53-3afb-4d0a-b2dc-bcd5c496fa3c	16e7fcab-101f-498c-8989-062ec832c8b8	1	Bentuk dan Ukuran	10	0	0	0	0	0	0	1	\N	\N	0	10	0	1	PEKERJAAN KLINIK
8481216e-1fac-4ea6-8771-143ebc9c27d3	16e7fcab-101f-498c-8989-062ec832c8b8	4	Kondisi radiograf	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
d4a10422-327d-4145-bdf9-35273f045d43	16e7fcab-101f-498c-8989-062ec832c8b8	5	Posisi Objek	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
e2965e26-c22c-444f-acfd-0435e19bd2c3	16e7fcab-101f-498c-8989-062ec832c8b8	6	Posisi Penempatan Film	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
bb6d820f-763d-4d37-8e7d-6b7e0b39c9fa	16e7fcab-101f-498c-8989-062ec832c8b8	0	SIKAP	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	SIKAP
4a3025aa-89ef-47e7-bc9b-e225961d5e96	16e7fcab-101f-498c-8989-062ec832c8b8	1	Inisiatif	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
cb3c9233-1a22-4e9e-bee8-52ad0ce7f431	16e7fcab-101f-498c-8989-062ec832c8b8	2	Disiplin	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
49dd2a5e-d385-4e69-833d-e5531617f909	16e7fcab-101f-498c-8989-062ec832c8b8	3	Kejujuran	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
b9241d97-c626-4f27-bd8d-06d407117390	16e7fcab-101f-498c-8989-062ec832c8b8	4	Tanggung Jawab	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
cba0017f-6ef6-4e41-8865-596d223f4cc8	16e7fcab-101f-498c-8989-062ec832c8b8	5	Kerjasama	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
bcce051c-8bfe-4622-bae7-0edf1602f9e8	16e7fcab-101f-498c-8989-062ec832c8b8	6	Santun terhadap pasien	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
64a1ec32-4595-40e3-977f-53d0e5454c12	16e7fcab-101f-498c-8989-062ec832c8b8	7	Santun terhadap dosen	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
8f52a0c4-e0af-4790-9dfe-c66e1e59a769	97e25278-15f0-4436-9413-548ddb1edac2	0	PEKERJAAN KLINIK	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	PEKERJAAN KLINIK
2141ceeb-182a-43b0-bd7a-52824be88de3	97e25278-15f0-4436-9413-548ddb1edac2	1	Menilai kualitas radiograf :\n1.\tkontras radiograf : nilai kontras yang baik jika gambaran jaringan terlihat dengan jelas (radiopak dan radiolusen jelas)\n2.\tKetajaman (Sharpness) Radiograf : Ketajaman (sharpness) didefinisikan sebagai kemampuan dari suatu radiograf untuk menjelaskan tepi atau batas-batas dari objek yang tampak\n3.\tDetail Radiograf : Detail radiograf menjelaskan tentang bagian terkecil dari objek masih dapat tervisualisasi dengan baik pada radiograf (perbedaan tiap objek misal: dentin, email)\n4.\tDensitas suatu radiograf  :  keseluruhan derajat penghitaman pada sebuah film/reseptor yang telah diberikan paparan radiasi diukur sebagai densitas optik dari area suatu film. Densitas ini bergantung pada ketebalan objek, densitas objek, dan tingkat pemaparan sinar x.\n5.\tBrightness : keseimbangan antara warna terang dan gelap pada suatu gambaran radiografi.	10	0	0	0	0	0	0	1	\N	\N	0	10	0	1	PEKERJAAN KLINIK
46f34477-d061-415d-a758-cce20808b860	97e25278-15f0-4436-9413-548ddb1edac2	2	Interpretasi mahkota :\n1. Densitas: radioopak/radiolusen\n2. Lokasi: oklusal/proximal/cervikal\n3. Kedalaman: meliputi elemen gigi apa (sampai email/dentin/pulpa)	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	PEKERJAAN KLINIK
ed973d87-518c-4955-b6b6-ddbe882874a7	97e25278-15f0-4436-9413-548ddb1edac2	3	Interpretasi akar:\n1. Jumlah akar : tunggal(1)/2,3\n2. Bentuk akar : divergen/konvergen/Dilaserasi\n3.\tDensitas : radioopak/radiolusen	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	PEKERJAAN KLINIK
f647001a-5c86-43bf-9106-83598fff9516	97e25278-15f0-4436-9413-548ddb1edac2	4	Interpretasi ruang membran periodontal :\n1. DBN/menghilang/ melebar\n2. Lokasi : seluruh akar/ 1/3 apikal  dll	2	0	0	0	0	0	0	1	\N	2024-04-01 10:31:24	0	2	0	1	["kode_sub_name"]
f027a75a-593b-410f-a042-2229183972f0	97e25278-15f0-4436-9413-548ddb1edac2	5	Interpretasi laminadura :\n1. DBN/terputus/menghilang/menebal\n2. Lokasi : seluruh akar/ 1/3 apikal  dll	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	PEKERJAAN KLINIK
3a435e7d-86b2-4f46-9505-04dc3e37b787	97e25278-15f0-4436-9413-548ddb1edac2	6	Interpretasi puncak tulang alveolar :\n1.DBN(1-3mm)/mengalami penurunan\n2.Tipe penurunan (vertikal/horizontal)\n3.Berapa mm penurunan puncak tulang alveolar dari CEJ	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	PEKERJAAN KLINIK
b410da6f-73e1-4ecf-8fb8-cadda23be168	97e25278-15f0-4436-9413-548ddb1edac2	7	Interpretasi furkasi : \n1. pelebaran membran\n2. Penurunan tulang alveor\n3 radiolusen/radioopak/DBN	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	PEKERJAAN KLINIK
c6df03b3-84c9-4d0c-bb0d-8f76f36c7419	97e25278-15f0-4436-9413-548ddb1edac2	8	Interpretasi periapikal \n1. Site : lokasi at regio apa\n2. Size : ukuran x.y mm/ sebesar kacang polong dll\n3. Shape : bulat/oval/reguler/irreguler\n4. Symmetry\n5. Borders : batas jelas dan tegas/ jelas tidak tegas/ tidak jelas dan tidak tegas/ reguler/irreguler\n6. Contents :\nradiolusen/radioopak/mixed\n7. Associations : hub/efek terhadap struktur lain disekitarnya\n8. Jumlah : unilokuler/multilokuler	10	0	0	0	0	0	0	1	\N	\N	0	10	0	1	PEKERJAAN KLINIK
57660cb0-2e51-429b-8a0e-7451e240581b	97e25278-15f0-4436-9413-548ddb1edac2	9	Membuat Kesan :\nMenyebutkan kelainan pada setiap elemen.\n“Terdapat kelainan pada mahkota, akar...”	3	0	0	0	0	0	0	1	\N	\N	0	3	0	1	PEKERJAAN KLINIK
7328821c-6c9d-4d15-90c2-bce444ccfca0	97e25278-15f0-4436-9413-548ddb1edac2	10	Menentukan suspect radiodiagnosis	10	0	0	0	0	0	0	1	\N	\N	0	10	0	1	PEKERJAAN KLINIK
d01d7288-4615-49ae-a513-91f0de6eeda6	97e25278-15f0-4436-9413-548ddb1edac2	11	Menentukan differensial diagnosis	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
5cb67473-39fb-45f1-a078-99115cbc3cda	97e25278-15f0-4436-9413-548ddb1edac2	0	SIKAP	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	SIKAP
6ea2b1b7-021a-4a4a-9680-70c1eeba4d66	97e25278-15f0-4436-9413-548ddb1edac2	1	Inisiatif	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
eb443a45-4e06-4d2a-8165-f9f7f8e84202	97e25278-15f0-4436-9413-548ddb1edac2	2	Disiplin	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
6e5b56e6-de53-4d93-9e09-2a55ab432263	97e25278-15f0-4436-9413-548ddb1edac2	3	Kejujuran	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
6f32d2d7-3f87-4d02-b21a-04e6f343e737	97e25278-15f0-4436-9413-548ddb1edac2	4	Tanggung Jawab	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
e77bd997-c5c6-4ede-b247-058097ee1c66	97e25278-15f0-4436-9413-548ddb1edac2	5	Kerjasama	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
047b171d-76b9-4841-bb65-fc760627fcb5	97e25278-15f0-4436-9413-548ddb1edac2	6	Santun terhadap pasien	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
600cbb17-16fc-4180-ba24-109974958040	97e25278-15f0-4436-9413-548ddb1edac2	7	Santun terhadap dosen	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
761d0b8c-cb80-49f9-b877-018309f21082	4446af12-f58b-4c5f-ae83-f21f880733ca	0	PEKERJAAN KLINIK	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	PEKERJAAN KLINIK
810acf56-210c-4c19-8eeb-83e41bc5d14e	4446af12-f58b-4c5f-ae83-f21f880733ca	1	Informed Consent	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
567a0c85-2862-40b7-b8cd-a772c51f83f8	4446af12-f58b-4c5f-ae83-f21f880733ca	2	Proteksi Radiasi	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
02a8fb47-4459-459f-9ab4-88a9d3a65fec	4446af12-f58b-4c5f-ae83-f21f880733ca	3	Posisi Pasien	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
20c1f9dc-2fe1-4eb6-9e43-72452e4d3244	4446af12-f58b-4c5f-ae83-f21f880733ca	4	Posisi Film	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
b7e4d230-857e-4f80-b88c-ab430e0e23dc	4446af12-f58b-4c5f-ae83-f21f880733ca	5	Posisi Tabung Xray	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
58a654a7-a9cc-42e9-a342-a00d32a4e471	4446af12-f58b-4c5f-ae83-f21f880733ca	6	Instruksi Pasien	10	0	0	0	0	0	0	1	\N	\N	0	10	0	1	PEKERJAAN KLINIK
c5099f0e-93cc-41e4-a75a-6de62933359c	4446af12-f58b-4c5f-ae83-f21f880733ca	7	Exposure	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
b34d6928-6031-407e-bd2b-78aa8f94386b	4446af12-f58b-4c5f-ae83-f21f880733ca	0	SIKAP	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	SIKAP
35a6f7de-cc82-4552-a258-60b809b4fbb0	4446af12-f58b-4c5f-ae83-f21f880733ca	1	Inisiatif	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
904530b2-b824-43ba-b926-389bd8d27136	4446af12-f58b-4c5f-ae83-f21f880733ca	2	Disiplin	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
4dc60b85-5210-46ae-a727-dd59daf6ffd7	4446af12-f58b-4c5f-ae83-f21f880733ca	3	Kejujuran	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
f645b98b-a061-469f-a625-c9e984069939	4446af12-f58b-4c5f-ae83-f21f880733ca	4	Tanggung Jawab	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
ca9e8e4c-d40d-4df0-8a7d-2f7491a2b22b	4446af12-f58b-4c5f-ae83-f21f880733ca	5	Kerjasama	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
623e3ee0-47e8-46fc-9882-556bd798a990	4446af12-f58b-4c5f-ae83-f21f880733ca	6	Santun terhadap pasien	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
56a47c3a-12b0-4743-b8cd-42d522356f7a	4446af12-f58b-4c5f-ae83-f21f880733ca	7	Santun terhadap dosen	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
8289bd4d-bfde-40c7-9810-f7e560975962	01977c96-2356-488f-a656-10ddc52fd53c	0	PEKERJAAN KLINIK	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	PEKERJAAN KLINIK
7527f034-cb9a-4d6f-9413-8cf5eb130a0a	01977c96-2356-488f-a656-10ddc52fd53c	1	Bentuk dan Ukuran	10	0	0	0	0	0	0	1	\N	\N	0	10	0	1	PEKERJAAN KLINIK
b0533b31-efde-443e-a978-faeaffc272d1	01977c96-2356-488f-a656-10ddc52fd53c	4	Kondisi radiograf	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
17735793-cea9-4b6d-83b1-0c5bfa19f5e1	01977c96-2356-488f-a656-10ddc52fd53c	5	Posisi Objek	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
714772f6-3c4c-4161-807c-bea896c394a4	01977c96-2356-488f-a656-10ddc52fd53c	6	Posisi Penempatan Film	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
ee775ee2-9886-4f68-bb41-63b3e9bcecae	01977c96-2356-488f-a656-10ddc52fd53c	0	SIKAP	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	SIKAP
259c60b8-e5e5-476b-b939-3d8675cf9d7b	01977c96-2356-488f-a656-10ddc52fd53c	1	Inisiatif	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
cc07bb11-bd65-42f2-8fa3-5e43d899a3ec	01977c96-2356-488f-a656-10ddc52fd53c	2	Disiplin	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
9b1b78e3-8340-487b-b7a4-2140cc1e4a48	01977c96-2356-488f-a656-10ddc52fd53c	3	Kejujuran	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
9c69c9fe-4e68-44b0-9c84-d05391320582	01977c96-2356-488f-a656-10ddc52fd53c	4	Tanggung Jawab	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
b180036b-216b-4968-b647-56cd9acabd5c	01977c96-2356-488f-a656-10ddc52fd53c	5	Kerjasama	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
15aef6c4-8724-4ee3-8700-4d377d986d73	01977c96-2356-488f-a656-10ddc52fd53c	6	Santun terhadap pasien	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
3c4dafda-b66c-45fb-b677-15c5dc5e0a35	01977c96-2356-488f-a656-10ddc52fd53c	7	Santun terhadap dosen	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
178ede31-429f-4789-87c4-10cfe51433d1	608ea017-a9c9-4c54-9870-d82ad90c868e	0	PEKERJAAN KLINIK	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	PEKERJAAN KLINIK
55dbc8b0-787e-4e87-999d-22ad5f4bc2ea	608ea017-a9c9-4c54-9870-d82ad90c868e	1	Menilai kualitas radiograf :\n6.\tkontras radiograf : nilai kontras yang baik jika gambaran jaringan terlihat dengan jelas (radiopak dan radiolusen jelas)\n7.\tKetajaman (Sharpness) Radiograf : Ketajaman (sharpness) didefinisikan sebagai kemampuan dari suatu radiograf untuk menjelaskan tepi atau batas-batas dari objek yang tampak\n8.\tDetail Radiograf : Detail radiograf menjelaskan tentang bagian terkecil dari objek masih dapat tervisualisasi dengan baik pada radiograf (perbedaan tiap objek misal: dentin, email)\n9.\tDensitas suatu radiograf  :  keseluruhan derajat penghitaman pada sebuah film/reseptor yang telah diberikan paparan radiasi diukur sebagai densitas optik dari area suatu film. Densitas ini bergantung pada ketebalan objek, densitas objek, dan tingkat pemaparan sinar x.\n10.\tBrightness : keseimbangan antara warna terang dan gelap pada suatu gambaran radiografi.	10	0	0	0	0	0	0	1	\N	\N	0	10	0	1	PEKERJAAN KLINIK
019f7fb4-2ac7-4cc4-8fbc-86602cab53b2	700d3334-6b14-4b7a-8973-dc0470f55c51	7	Santun terhadap dosen	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
1ca15f03-202e-4ec3-9587-9512377846f7	608ea017-a9c9-4c54-9870-d82ad90c868e	2	Interpretasi mahkota :\n1. Densitas: radioopak/radiolusen\n2. Lokasi: oklusal/proximal/cervikal\n3. Kedalaman: meliputi elemen gigi apa (sampai email/dentin/pulpa)	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	PEKERJAAN KLINIK
89d5f270-9bf7-43ce-a136-ea66e9cf168e	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	0	PEKERJAAN KLINIK	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	PEKERJAAN KLINIK
5754d680-1cee-44e7-bbea-751ee3ea55d5	608ea017-a9c9-4c54-9870-d82ad90c868e	3	Interpretasi akar:\n1. Jumlah akar : tunggal(1)/2,3\n2. Bentuk akar : divergen/konvergen/Dilaserasi\n4.\tDensitas : radioopak/radiolusen	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	PEKERJAAN KLINIK
17c07d88-7300-4719-9678-cb4ddea3a18b	608ea017-a9c9-4c54-9870-d82ad90c868e	4	Interpretasi ruang membran periodontal :\n1. DBN/menghilang/ melebar\n2. Lokasi : seluruh akar/ 1/3 apikal dll	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	PEKERJAAN KLINIK
088b1b5a-d66e-48ac-ae06-3b98c8630f9f	608ea017-a9c9-4c54-9870-d82ad90c868e	5	Interpretasi laminadura :\n1. DBN/terputus/menghilang/menebal\n2. Lokasi : seluruh akar/ 1/3 apikal dll	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	PEKERJAAN KLINIK
ef9dc18d-a45f-4c0d-b8bd-016c669d78cf	608ea017-a9c9-4c54-9870-d82ad90c868e	6	Interpretasi puncak tulang alveolar :\n1.DBN(1-3mm)/mengalami penurunan\n2.Tipe penurunan (vertikal/horizontal)\n3.Berapa mm penurunan puncak tulang alveolar dari CEJ	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	PEKERJAAN KLINIK
1eabb88a-3425-4a36-aa82-afa073814f40	608ea017-a9c9-4c54-9870-d82ad90c868e	7	Interpretasi furkasi : \n1. pelebaran membran\n2. Penurunan tulang alveor\n3 radiolusen/radioopak/DBN	2	0	0	0	0	0	0	1	\N	\N	0	2	0	1	PEKERJAAN KLINIK
ad6ca5a2-8152-4c5a-b63d-79e2a2ee90b0	608ea017-a9c9-4c54-9870-d82ad90c868e	8	Interpretasi periapikal \n1. Site : lokasi at regio apa\n2. Size : ukuran x.y mm/ sebesar kacang polong dll\n3. Shape : bulat/oval/reguler/irreguler\n4. Symmetry\n5. Borders : batas jelas dan tegas/ jelas tidak tegas/ tidak jelas dan tidak tegas/ reguler/irreguler\n6. Contents :\nradiolusen/radioopak/mixed\n7. Associations : hub/efek terhadap struktur lain disekitarnya\n8. Jumlah : unilokuler/multilokuler	10	0	0	0	0	0	0	1	\N	\N	0	10	0	1	PEKERJAAN KLINIK
6e182dd4-f341-4621-9e16-e5248702f9c7	608ea017-a9c9-4c54-9870-d82ad90c868e	9	Membuat Kesan :\nMenyebutkan kelainan pada setiap elemen.\n“Terdapat kelainan pada mahkota, akar...”	3	0	0	0	0	0	0	1	\N	\N	0	3	0	1	PEKERJAAN KLINIK
10de4d3a-bba0-47f5-ae35-e5fb819923a7	608ea017-a9c9-4c54-9870-d82ad90c868e	10	Menentukan suspect radiodiagnosis	10	0	0	0	0	0	0	1	\N	\N	0	10	0	1	PEKERJAAN KLINIK
9fb2de18-6c2d-4ce7-b60f-40c478f1fef7	608ea017-a9c9-4c54-9870-d82ad90c868e	11	Menentukan differensial diagnosis	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
4f0af24c-a395-4bfd-92c5-e8dbe0f6dae3	608ea017-a9c9-4c54-9870-d82ad90c868e	0	SIKAP	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	SIKAP
3fa4d321-b195-4312-a16f-a01f601447bd	608ea017-a9c9-4c54-9870-d82ad90c868e	1	Inisiatif	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
17e76aac-9485-412a-9282-028a1ac90e9b	608ea017-a9c9-4c54-9870-d82ad90c868e	2	Disiplin	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
d03fd532-2c6d-47ca-b1ff-1dde9ae6596d	608ea017-a9c9-4c54-9870-d82ad90c868e	3	Kejujuran	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
fe5b0c0d-9b9b-4f9e-9035-9f2f9d7a21a0	608ea017-a9c9-4c54-9870-d82ad90c868e	4	Tanggung Jawab	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
231cf889-791d-46b3-9b9b-7c05c31bef1d	608ea017-a9c9-4c54-9870-d82ad90c868e	5	Kerjasama	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
25b6e277-b588-4df5-96f8-56f9a72ec27b	608ea017-a9c9-4c54-9870-d82ad90c868e	6	Santun terhadap pasien	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
82ca3463-64fa-4439-adb9-bc2a21df6dd0	608ea017-a9c9-4c54-9870-d82ad90c868e	7	Santun terhadap dosen	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
3e66cba6-b744-46da-8baf-cb77bd677fa4	79d64714-b496-414a-a28c-5cfd319280e9	0	PEKERJAAN KLINIK	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	PEKERJAAN KLINIK
14a3f7d0-bcf3-4884-b620-c8f8e72a7b42	79d64714-b496-414a-a28c-5cfd319280e9	1	Site : lokasi at regio	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
94d4e79e-09b6-4188-80d5-65d3dfd25370	79d64714-b496-414a-a28c-5cfd319280e9	7	Associations : hub/efek terhadap struktur lain disekitarnya	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
a9d00a52-2a54-46af-b6a1-a33347e84bcc	79d64714-b496-414a-a28c-5cfd319280e9	9	Suspek Radiodiagnosis	10	0	0	0	0	0	0	1	\N	\N	0	10	0	1	PEKERJAAN KLINIK
1c95a8ad-f56e-4afd-aaa6-11f8ab73c58d	79d64714-b496-414a-a28c-5cfd319280e9	10	DD	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
e098aae3-ad03-4424-b3e2-82d47c59504e	79d64714-b496-414a-a28c-5cfd319280e9	0	SIKAP	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	SIKAP
c6892221-3a8c-427b-a7dc-76d4c9576c50	79d64714-b496-414a-a28c-5cfd319280e9	1	Inisiatif	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
d4488ac8-5ad1-4dc9-9d4e-e530d5be0176	79d64714-b496-414a-a28c-5cfd319280e9	2	Disiplin	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
98e4091f-768a-4666-b1b1-8873ad519d51	79d64714-b496-414a-a28c-5cfd319280e9	3	Kejujuran	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
e26cb3a0-ea51-447e-8bc0-e21e9e8938d4	79d64714-b496-414a-a28c-5cfd319280e9	4	Tanggung Jawab	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
0bfe6537-d840-4960-b452-bc8c9d91f801	79d64714-b496-414a-a28c-5cfd319280e9	5	Kerjasama	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
3faef3fc-517a-4bf9-9c01-e824298d4cfc	79d64714-b496-414a-a28c-5cfd319280e9	6	Santun terhadap pasien	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
79d412d7-0b8d-44ed-a9d2-5763b684a0d8	79d64714-b496-414a-a28c-5cfd319280e9	7	Santun terhadap dosen	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
782aa962-1ddb-4442-9db2-fa43946848bd	2569196c-7dfd-4ab3-9845-0cc1fe7fc1e9	0	SIKAP	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	SIKAP
0209f583-008f-414b-bcf7-7a389dbf224d	2569196c-7dfd-4ab3-9845-0cc1fe7fc1e9	1	Inisiatif	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
a889ca74-b784-43e1-90c0-5833b32898df	2569196c-7dfd-4ab3-9845-0cc1fe7fc1e9	2	Disiplin	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
d70c5578-b960-4272-9e36-01bfc68586d5	2569196c-7dfd-4ab3-9845-0cc1fe7fc1e9	3	Kejujuran	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
47a4695a-8eca-4d21-8ae5-dee4e708794d	2569196c-7dfd-4ab3-9845-0cc1fe7fc1e9	4	Tanggung Jawab	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
a91e2a00-a885-49d4-8ca0-b442b3b10dfd	2569196c-7dfd-4ab3-9845-0cc1fe7fc1e9	5	Kerjasama	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
8a748853-439a-49be-8dd8-26745b5e3bdb	2569196c-7dfd-4ab3-9845-0cc1fe7fc1e9	6	Santun terhadap Pasien	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
52c00875-ff5b-40fa-bf03-2c57d786c6ec	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	0	PEKERJAAN KLINIK	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	PEKERJAAN KLINIK
3be73c17-b7d0-40b8-a16f-a64591c5a9e5	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	5	Pasien diinstruksikan untuk memakai apron pelindung radiasi	3	0	0	0	0	0	0	1	\N	2024-04-23 20:05:16	0	3	0	1	["kode_sub_name"]
f7f56eee-c3b2-4196-88fe-0b6ee19d17f4	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	4	Menggunakan Masker dan Sarung tangan	2	0	0	0	0	0	0	1	\N	2024-04-23 20:05:24	0	2	0	1	["kode_sub_name"]
8db2983a-640f-4476-bf2f-82fbecefe22a	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	3	Mempersilahkan  pasien  untuk  masuk  dan\nmenjelaskan kepada pasien prosedur pemeriksaan radiologis menggunakan teknik periapikal bisektris	5	0	0	0	0	0	0	1	\N	2024-04-23 20:05:34	0	5	0	1	["kode_sub_name"]
e9fe4b01-3356-4836-9b40-b6e2c1f4e246	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	2	Mempersiapkan alat xray intraoral, memilih lama eksposur pada panel kontrol dan film yang akan digunakan	2	0	0	0	0	0	0	1	\N	2024-04-23 20:05:53	0	2	0	1	["kode_sub_name"]
af6edd83-b741-499f-9f5f-3092fcea10e3	8f01380d-cf81-4e20-9fb1-6e416b18ab5a	0	PEKERJAAN KLINIK	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	PEKERJAAN KLINIK
0d5962c7-e8c1-4cd9-a027-1cd9bf310377	8f01380d-cf81-4e20-9fb1-6e416b18ab5a	1	Isi	15	0	0	0	0	0	0	1	\N	\N	0	15	0	1	PEKERJAAN KLINIK
6e69afdb-02e4-49c5-a39d-599bf2c562dc	8f01380d-cf81-4e20-9fb1-6e416b18ab5a	2	Presentasi: ppt, kejelasan suara, sistematis, semangat, gaya	10	0	0	0	0	0	0	1	\N	\N	0	10	0	1	PEKERJAAN KLINIK
0877dfa9-e93e-499f-a437-c89e1146dc3b	8f01380d-cf81-4e20-9fb1-6e416b18ab5a	3	Kemampuan menerangkan	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
bf801d5f-f2cc-48d4-bcae-ba58945de9f7	8f01380d-cf81-4e20-9fb1-6e416b18ab5a	4	Kemampuan menjawab dan diskusi	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
f0661ff0-e422-4a37-8e34-b487d39bac7e	8f01380d-cf81-4e20-9fb1-6e416b18ab5a	5	Sikap	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
d86aad7c-9003-4d24-ab0b-32a754ad880c	8f01380d-cf81-4e20-9fb1-6e416b18ab5a	0	SIKAP	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	SIKAP
db5bef52-9fd3-49bf-b805-35b5e8128a0a	8f01380d-cf81-4e20-9fb1-6e416b18ab5a	1	Inisiatif	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
9ce7810c-dd59-42c5-9b4b-c8d084be483c	8f01380d-cf81-4e20-9fb1-6e416b18ab5a	2	Disiplin	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
dcd6c8f5-e34a-46ce-8839-de1516ea16a2	8f01380d-cf81-4e20-9fb1-6e416b18ab5a	3	Kejujuran	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
f804e7c5-367e-4ad8-b9ee-28ee8e0a932b	8f01380d-cf81-4e20-9fb1-6e416b18ab5a	4	Tanggung Jawab	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
47a90071-4d37-49dc-b275-b5a0de2a9b87	8f01380d-cf81-4e20-9fb1-6e416b18ab5a	5	Kerjasama	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
0825bb70-afd3-4d76-a91a-6f9fea72a665	8f01380d-cf81-4e20-9fb1-6e416b18ab5a	6	Santun terhadap rekan	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
272709d1-add1-4d0e-a1e1-7afb5104fbf0	8f01380d-cf81-4e20-9fb1-6e416b18ab5a	7	Santun terhadap dosen	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
512a4232-a0f9-4b42-931f-e63a3c4db4f9	700d3334-6b14-4b7a-8973-dc0470f55c51	0	PEKERJAAN KLINIK	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	PEKERJAAN KLINIK
1bed3bf5-e364-4345-8aba-376231eaa3a0	700d3334-6b14-4b7a-8973-dc0470f55c51	1	Informed Consent	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
65c55213-9613-485b-8921-f4487598bcc2	700d3334-6b14-4b7a-8973-dc0470f55c51	2	Proteksi Radiasi	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
9a35780a-1033-4fdd-aaa8-8580a5281882	700d3334-6b14-4b7a-8973-dc0470f55c51	3	Posisi Pasien	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
f6015203-a9cc-44ba-b39f-9fc31389dbf8	700d3334-6b14-4b7a-8973-dc0470f55c51	4	Posisi Film	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
a7794545-1f0c-4712-84c5-1cb9679a2487	700d3334-6b14-4b7a-8973-dc0470f55c51	5	Posisi Tabung Xray	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
2badf227-f96f-4e56-aa7e-fe503db46de9	700d3334-6b14-4b7a-8973-dc0470f55c51	6	Instruksi Pasien	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
89cb9879-b7e4-46b8-91e9-b7e72dd32114	700d3334-6b14-4b7a-8973-dc0470f55c51	7	Exposure	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
567af7c7-13d4-4335-a190-dd62b4d3c7ea	700d3334-6b14-4b7a-8973-dc0470f55c51	8	Prosesing	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
04f80df0-b91b-4e30-a084-e2419552e8e7	700d3334-6b14-4b7a-8973-dc0470f55c51	0	SIKAP	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	SIKAP
2ef434b4-1489-4feb-9403-6372580cef3b	700d3334-6b14-4b7a-8973-dc0470f55c51	1	Inisiatif	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
8c97c0b9-ede4-4286-b683-b46222bdb97c	700d3334-6b14-4b7a-8973-dc0470f55c51	2	Disiplin	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
d2e0746f-6048-406b-bcda-543906055701	700d3334-6b14-4b7a-8973-dc0470f55c51	3	Kejujuran	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
b6ffd467-4337-468d-b282-3628665408a4	700d3334-6b14-4b7a-8973-dc0470f55c51	4	Tanggung Jawab	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
0ee7a1eb-1be0-4c40-9bd9-d3022e136c59	700d3334-6b14-4b7a-8973-dc0470f55c51	5	Kerjasama	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
c5e602b4-37b2-448b-970f-f7915d4b0a46	700d3334-6b14-4b7a-8973-dc0470f55c51	6	Santun terhadap pasien	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
8520b176-2b33-459f-bf63-97a3e153e45d	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	1	Informed Consent	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
7236b2ff-217d-4998-9ef3-41b144e453f4	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	2	Proteksi Radiasi	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
666c4222-69c1-421b-8200-a10290440162	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	14	Mempersilahkan  pasien  kembali  ke  ruang tunggu untuk menunggu hasil radiograf.	1	0	0	0	0	0	0	1	\N	2024-04-23 20:09:13	0	1	0	1	["kode_sub_name"]
fe20ae99-30ce-4cea-a454-37359f16c3bd	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	1	Inisiatif	0	0	0	0	5-14	5	14	1	\N	2024-04-23 20:09:56	0	0	0	2	["kode_sub_name"]
7eab875a-ad52-4ff2-971b-63e30724b03c	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	2	Disiplin	0	0	0	0	5-14	5	14	1	\N	2024-04-23 20:10:20	0	0	0	2	["kode_sub_name"]
af754f5e-cdef-4660-bc34-2bc09e06bc26	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	3	Kejujuran	0	0	0	0	5-14	5	14	1	\N	2024-04-23 20:10:28	0	0	0	2	["kode_sub_name"]
6a89654c-909f-43e3-ab47-d39c30037418	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	4	Tanggung Jawab	0	0	0	0	5-14	5	14	1	\N	2024-04-23 20:10:39	0	0	0	2	["kode_sub_name"]
dc8f07b1-45cd-4977-8ce2-312f5455bf19	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	6	Santun terhadap Pasien	0	0	0	0	5-14	5	14	1	\N	2024-04-23 20:11:14	0	0	0	2	["kode_sub_name"]
a8e52691-7aa2-4ade-8323-e4e5495fb63b	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	7	Santun terhadap dosen	0	0	0	0	5-14	5	14	1	\N	2024-04-23 20:11:24	0	0	0	2	["kode_sub_name"]
cffbd13b-a92e-46f6-a65a-208136261a11	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	12	Memencet tombol eksposi	1	0	0	0	0	0	0	1	\N	2024-04-23 20:11:41	0	1	0	1	["kode_sub_name"]
43f89f49-b5ff-47c6-8b41-f6532256ad31	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	11	Menginstruksikan pasien untuk tidak bergerak   dan   dan   menjelaskan   operator akan melakukan eksposi	1	0	0	0	0	0	0	1	\N	2024-04-23 20:11:49	0	1	0	1	["kode_sub_name"]
ab29848c-1713-44d0-8ae6-8ff7a15a7d5d	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	10	Mengarahkan tabung eksposi sesuai dengan titik penetrasi objek.	5	0	0	0	0	0	0	1	\N	2024-04-23 20:11:56	0	5	0	1	["kode_sub_name"]
26fb5ed1-f586-4805-b431-c73e532b850e	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	9	Mengatur Tabung eksposi pada:\na. Sudut vertikal disesuaikan objek yang akan diperiksa\nb. Sudut Horizontal disesuaikan objek yang akan diperiksa	10	0	0	0	0	0	0	1	\N	2024-04-23 20:12:08	0	10	0	1	["kode_sub_name"]
40aa31de-c592-40b9-a2f0-99b45f6d0b94	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	7	Meletakkan film   intraoral kedalam mulut pasien, posisi objek yang akan diperiksa berada di  tengah film. Dot  film  berada  di insisal/oklusal gigi.	5	0	0	0	0	0	0	1	\N	2024-04-23 20:12:16	0	5	0	1	["kode_sub_name"]
c36494b4-8f30-4b6a-8020-84a37b4b80ca	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	0	SIKAP	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	SIKAP
326fef6b-1ae2-4248-89a4-991922cbb136	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	3	Posisi Pasien	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
b9302baf-0246-4848-bc4c-16423150724b	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	4	Posisi Film	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
169344ad-20af-4905-a2b5-7585fa61fb06	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	5	Posisi Tabung Xray	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
cdcbb703-4912-4b17-9b7b-be748d7ae249	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	6	Instruksi Pasien	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
ec8f5218-ecf9-461f-bbeb-2df2dad9285d	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	7	Exposure	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
0168ed48-f471-4cc5-a9e0-d51cb5737ac1	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	8	Prosesing	5	0	0	0	0	0	0	1	\N	\N	0	5	0	1	PEKERJAAN KLINIK
fbac69ca-23dc-454d-b77f-9777a32d7a5d	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	0	SIKAP	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	SIKAP
b5d94bd4-dcfc-4602-9297-c00847852dea	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	1	Inisiatif	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
518e948d-dd5a-42a7-9cd8-df35a6510b88	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	2	Disiplin	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
f603ceea-42c3-49a7-a9ab-0ee3227a2e72	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	3	Kejujuran	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
4009e0ce-7dc9-407e-be56-7292002c9f1f	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	4	Tanggung Jawab	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
24d7d73c-d5e9-4868-93b7-de9229b499a2	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	5	Kerjasama	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
8c4c52d4-baf1-43d2-a6cb-cd62259bc6e7	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	6	Santun terhadap pasien	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
e9e25456-79dc-47b5-8e6d-5615706020ab	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	7	Santun terhadap dosen	0	0	0	0	5-14	5	14	1	\N	\N	0	0	0	2	SIKAP
a0e62521-de01-4d8f-9b97-51fd13cda9e3	a7a33913-a538-4c67-b755-5ee038e5c2d0	1	Pemeriksaan (18-30)	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	Pemeriksaan (18-30)
0eeab29b-b37f-4920-9577-89d258101a27	a7a33913-a538-4c67-b755-5ee038e5c2d0	2	a. Informed consent	0	5	3	5	100	0	100	1	\N	2024-04-03 14:15:37	0	0	0	1	["kode_sub_name"]
0707607f-7cbf-4c8b-a09d-3d1f768bd719	a7a33913-a538-4c67-b755-5ee038e5c2d0	3	b. Pengisian data pasien/ wawancara	0	5	3	5	100	0	100	1	\N	\N	0	0	0	1	Pemeriksaan (18-30)
09153e7c-3749-45fa-8e32-c63d4ab128f5	a7a33913-a538-4c67-b755-5ee038e5c2d0	4	c. Pemeriksaan klinis ekstra oral	0	5	3	5	100	0	100	1	\N	\N	0	0	0	1	Pemeriksaan (18-30)
95f1006c-37fe-44a5-8b26-f85809a95470	a7a33913-a538-4c67-b755-5ee038e5c2d0	5	d. Pemeriksaan intra oral (pemeriksaan klinis, radiografis)	0	15	9	15	100	0	100	1	\N	\N	0	0	0	1	Pemeriksaan (18-30)
985e45b4-d027-4996-95b3-705a3062b1c2	a7a33913-a538-4c67-b755-5ee038e5c2d0	6	Diagnosis (15-25)	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	Diagnosis (15-25)
3df888a8-1b4e-4f21-b0b6-b424ec9e43f2	a7a33913-a538-4c67-b755-5ee038e5c2d0	7	Sesuai dengan hasil pemeriksaan	0	25	15	25	100	0	100	1	\N	\N	0	0	0	2	Diagnosis (15-25)
be59a51d-6ade-434e-9348-e2f633c16f96	a7a33913-a538-4c67-b755-5ee038e5c2d0	7	Sesuai dengan hasil pemeriksaan	0	25	15	25	100	0	100	1	\N	\N	0	0	0	2	Diagnosis (15-25)
faede7a6-75fa-417b-ab23-9166c34d45fd	a7a33913-a538-4c67-b755-5ee038e5c2d0	8	encana Perawatan (18-30)	0	0	0	0	0	0	0	1	\N	\N	0	0	3	3	encana Perawatan (18-30)
9c482226-0d3b-495f-b52f-19a761c0d368	a7a33913-a538-4c67-b755-5ee038e5c2d0	10	enyelesaian (0-15)	0	0	0	0	0	0	0	1	\N	\N	0	0	4	4	enyelesaian (0-15)
db2f21ba-2b2a-44a2-9b17-80d231573c6d	a7a33913-a538-4c67-b755-5ee038e5c2d0	11	a. Data rekam medik diselesaikan dalam 1 har	0	15	0	15	100	0	100	1	\N	\N	0	0	0	4	enyelesaian (0-15)
7191eb27-3ba0-4c24-941c-636eb67ab97c	a7a33913-a538-4c67-b755-5ee038e5c2d0	12	b. Data rekam medik diselesaikan >1 hari	0	15	0	15	100	0	100	1	\N	\N	0	0	0	4	enyelesaian (0-15)
c9c52dc4-a15d-4182-8d12-b3c3e2f4c2f6	a7a33913-a538-4c67-b755-5ee038e5c2d0	12	c. Data rekam medik diselesaikan >1 mimggu	0	15	0	15	100	0	100	1	\N	\N	0	0	0	4	enyelesaian (0-15)
adf65a56-8021-43a7-9b48-09810edb24ad	15b9c6b5-1016-45fa-9156-7530d932d311	1	Tahapan Pekerjaan	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	Tahapan Pekerjaan
f27f3ce3-63fb-4619-a64c-038b51e345a8	15b9c6b5-1016-45fa-9156-7530d932d311	2	Plak	0	50	0	50	100	0	100	1	\N	\N	0	0	0	1	Tahapan Pekerjaan
838b7a48-3ca2-4164-a028-2b54f1b8848f	15b9c6b5-1016-45fa-9156-7530d932d311	3	Karang Gigi	0	50	0	50	100	0	100	1	\N	\N	0	0	0	1	Tahapan Pekerjaan
1e01ead8-1b57-4d94-af7c-8ae0876ae911	a5f134ca-c412-431f-99a8-79ed079d2956	1	Indikasi (20)	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	Indikasi (20)
e3b1992c-a1cb-45c1-b850-86174e7517af	a5f134ca-c412-431f-99a8-79ed079d2956	2	Indikasi (20)	0	20	12	20	100	0	100	1	\N	2024-04-03 15:37:40	0	0	0	1	["kode_sub_name"]
36c29f7c-c128-45f7-a463-1cc00c6e3293	a5f134ca-c412-431f-99a8-79ed079d2956	3	Pembersihan Gigi (25)	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	Pembersihan Gigi (25)
ce517baa-baad-4ce5-a299-4e653992b896	a5f134ca-c412-431f-99a8-79ed079d2956	4	Melakukan pembersihan gigi, sebelumnya diberikan disclosing solution	0	15	15	25	100	0	100	1	\N	\N	0	0	0	2	Pembersihan Gigi (25)
3db03c7a-8018-47b1-9be4-c62b3250feb5	a5f134ca-c412-431f-99a8-79ed079d2956	5	Aplikasi (45)	0	0	0	0	0	0	0	1	\N	\N	0	0	3	3	Aplikasi (45)
fbfc9f74-3958-4614-804a-33d929381258	a5f134ca-c412-431f-99a8-79ed079d2956	6	a. Melakukan perawatan dengan bahan yang tepat	0	35	21	35	100	0	100	1	\N	\N	0	0	0	3	Aplikasi (45)
a56c5452-a54c-4087-8089-3a7985d3ff3d	a5f134ca-c412-431f-99a8-79ed079d2956	7	b. Melakukan cek oklusi	0	10	6	10	100	0	100	1	\N	\N	0	0	0	3	Aplikasi (45)
8794178a-2944-42cc-8c5d-b80f2d8305c0	a5f134ca-c412-431f-99a8-79ed079d2956	8	Kontrol (10)	0	0	0	0	0	0	0	1	\N	\N	0	0	4	4	Kontrol (10)
2e8e6590-a12d-4857-8d75-44acd5520e5f	a5f134ca-c412-431f-99a8-79ed079d2956	9	Sempurna (Utuh)	0	10	6	10	100	0	100	1	\N	\N	0	0	0	4	Kontrol (10)
847bb26e-2bb2-435f-8b4e-c4371eeb803c	4c58ddcf-c320-4bc3-b43a-e899997e48f6	1	Indikasi (20)	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	Indikasi (20)
a7fc9ca2-652b-45e7-a2d3-a659fdf81a31	4c58ddcf-c320-4bc3-b43a-e899997e48f6	2	Indikasi (20)	0	20	12	20	100	0	100	1	\N	\N	0	0	0	1	Indikasi (20)
dc6f30ee-f1fe-4abb-98b0-5b0827d9245c	4c58ddcf-c320-4bc3-b43a-e899997e48f6	3	Pembersihan Gigi (25)	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	Pembersihan Gigi (25)
40ce3881-d500-411f-a288-5dcf4f5b1435	4c58ddcf-c320-4bc3-b43a-e899997e48f6	4	a. Melakukan pembersihan gigi, sebelumnya diberikan disclosing solution	0	10	6	10	100	0	100	1	\N	\N	0	0	0	2	Pembersihan Gigi (25)
377738f0-42e4-49f2-9f92-4cdffba4eadd	4c58ddcf-c320-4bc3-b43a-e899997e48f6	5	b. Melakukan pembuangan jaringan keras	0	15	9	15	100	0	100	1	\N	\N	0	0	0	2	Pembersihan Gigi (25)
db892c32-29ee-4e57-b260-88b1d3d559e4	4c58ddcf-c320-4bc3-b43a-e899997e48f6	6	Aplikasi (45)	0	0	0	0	0	0	0	1	\N	\N	0	0	3	3	Aplikasi (45)
9ddb2005-6de9-4747-a43f-ff198a3fdd40	4c58ddcf-c320-4bc3-b43a-e899997e48f6	7	a. Melakukan perawatan dengan bahan yang tepat	0	35	21	35	100	0	100	1	\N	\N	0	0	0	3	Aplikasi (45)
dbd7e1ac-bdff-4cff-a916-719e3a44f8fb	4c58ddcf-c320-4bc3-b43a-e899997e48f6	8	b. Melakukan cek oklusi	0	10	6	10	100	0	100	1	\N	2024-04-03 15:51:24	0	0	0	3	["kode_sub_name"]
1beaaf81-93f7-4e15-9467-68437c653db2	4c58ddcf-c320-4bc3-b43a-e899997e48f6	9	Kontrol (10)	0	0	0	0	0	0	0	1	\N	\N	0	0	4	4	Kontrol (10)
3003a9c7-16c0-4229-a42c-3e8f687fa720	4c58ddcf-c320-4bc3-b43a-e899997e48f6	10	Sempurna (utuh)	0	10	6	10	100	0	100	1	\N	\N	0	0	0	4	Kontrol (10)
02abe8d0-7402-4ca2-8486-d830fd9d7e34	3fe495a9-74b4-4606-a185-9f5c056033f6	1	Preparasi (35)	0	35	21	35	100	0	100	1	\N	2024-04-03 15:56:20	0	0	0	1	["kode_sub_name"]
846bd2f3-f013-497b-aac4-4fd3900a3188	3fe495a9-74b4-4606-a185-9f5c056033f6	2	Dasar/liner (10)	0	10	6	10	100	0	100	1	\N	\N	0	0	0	1	Dasar/liner (10)
f266d7a0-1a4b-40e7-9a49-62513360584c	3fe495a9-74b4-4606-a185-9f5c056033f6	3	Etsa,bonding (20)	0	20	12	20	100	0	100	1	\N	\N	0	0	0	1	Etsa,bonding (20)
a3e082c5-0cfa-4693-a3de-403a98a98824	3fe495a9-74b4-4606-a185-9f5c056033f6	4	Penumpatan Komposit / Penumpatan Kompomer (25)	0	25	15	25	100	0	100	1	\N	\N	0	0	0	1	Penumpatan Komposit / Penumpatan Kompomer (25)
6739145c-ec58-41ab-af79-7c74d766d3a6	3fe495a9-74b4-4606-a185-9f5c056033f6	5	Kontrol/finishing/polishing (10)	0	10	6	10	100	0	100	1	\N	\N	0	0	0	1	Kontrol/finishing/polishing (10)
9abf651a-0bdb-40fe-a3f4-b7c756d20c68	4f078342-5e30-4774-abec-97a9d1c5abe9	1	Preparasi (35)	0	35	21	35	100	0	100	1	\N	\N	0	0	0	1	Preparasi (35)
adb3f46d-afe5-45fe-8e6c-30bfb902cdef	4f078342-5e30-4774-abec-97a9d1c5abe9	2	Dasar/liner (10)	0	10	6	10	100	0	100	1	\N	\N	0	0	0	1	Dasar/liner (10)
627eb09c-77e8-4d0a-a834-f7919bcb765b	4f078342-5e30-4774-abec-97a9d1c5abe9	3	Etsa,bonding (20)	0	20	12	20	100	0	100	1	\N	2024-04-03 16:07:13	0	0	0	1	["kode_sub_name"]
6d9652b3-dd85-4e94-b125-edac758a6d69	4f078342-5e30-4774-abec-97a9d1c5abe9	4	Penumpatan Komposit / Penumpatan Kompomer (25)	0	25	15	25	100	0	100	1	\N	\N	0	0	0	1	Penumpatan Komposit / Penumpatan Kompomer (25)
46369d9f-6283-4b33-9780-66aa11a87353	4f078342-5e30-4774-abec-97a9d1c5abe9	5	Kontrol/finishing/polishing (10)	0	10	6	10	100	0	100	1	\N	\N	0	0	0	1	Kontrol/finishing/polishing (10)
87644c3b-937b-4338-b5d3-1ea96411565f	4f8d29e6-8a8b-49e1-bd75-f295dc94ac0a	1	Preparasi (35)	0	35	21	35	100	0	100	1	\N	\N	0	0	0	1	Preparasi (35)
72da6f0d-d23b-48f9-8237-e1d202ddb2da	4f8d29e6-8a8b-49e1-bd75-f295dc94ac0a	2	Dasar/liner (10)	0	10	6	10	100	0	100	1	\N	\N	0	0	0	1	Dasar/liner (10)
dc6cd7da-0a35-4ead-9c37-fb7a511cd121	4f8d29e6-8a8b-49e1-bd75-f295dc94ac0a	3	Etsa,bonding (20)	0	20	12	20	100	0	100	1	\N	\N	0	0	0	1	Etsa,bonding (20)
9568a86d-51a2-404c-a96e-fef743241dd9	4f8d29e6-8a8b-49e1-bd75-f295dc94ac0a	4	Penumpatan Komposit / Penumpatan Kompomer (25)	0	25	15	25	100	0	100	1	\N	\N	0	0	0	1	Penumpatan Komposit / Penumpatan Kompomer (25)
5a5557a3-69ac-47b1-beff-6a8a21ff1611	4f8d29e6-8a8b-49e1-bd75-f295dc94ac0a	5	Kontrol/finishing/polishing (10)	0	10	6	10	100	0	100	1	\N	\N	0	0	0	1	Kontrol/finishing/polishing (10)
a4e6bc45-9f03-4641-9368-e891d1e39d57	b131b399-9b47-4b91-8504-d8047c6b3576	1	Preparasi (35)	0	35	21	35	100	0	100	1	\N	\N	0	0	0	1	Preparasi (35)
b6fa2215-e3a5-4c59-a0b7-7c93e4bd778c	b131b399-9b47-4b91-8504-d8047c6b3576	2	Dasar/liner (10)	0	10	6	10	100	0	100	1	\N	\N	0	0	0	1	Dasar/liner (10)
cc5279c2-c0bb-46fe-8c32-b0be3bec4204	b131b399-9b47-4b91-8504-d8047c6b3576	3	Etsa,bonding (20)	0	20	12	20	100	0	100	1	\N	\N	0	0	0	1	Etsa,bonding (20)
f95120e2-ce1f-472c-92d8-d31e0fcba068	b131b399-9b47-4b91-8504-d8047c6b3576	4	Penumpatan Komposit / Penumpatan Kompomer (25)	0	25	15	25	100	0	100	1	\N	\N	0	0	0	1	Penumpatan Komposit / Penumpatan Kompomer (25)
af13464b-4521-4c4b-ac6a-66447267607c	b131b399-9b47-4b91-8504-d8047c6b3576	5	Kontrol/finishing/polishing (10)	0	10	6	10	100	0	100	1	\N	\N	0	0	0	1	Kontrol/finishing/polishing (10)
ffb37b3e-2968-444c-bc4a-bec439319f38	56538202-f648-47fd-b32d-cd451cd08bce	1	Persiapan (20)	0	0	0	0	0	0	0	1	\N	\N	0	0	1	1	Persiapan (20)
b6d2626a-9bd9-4daf-a10d-218fc41cc6ea	56538202-f648-47fd-b32d-cd451cd08bce	2	a. Persiapan pasien, komunikasi (10)	0	10	6	10	100	0	100	1	\N	\N	0	0	0	1	Persiapan (20)
0c85f273-2057-415e-8a5b-e4cef80defa9	56538202-f648-47fd-b32d-cd451cd08bce	3	b. Persiapan alat dan bahan (5)	0	5	3	5	100	0	100	1	\N	\N	0	0	0	1	Persiapan (20)
738db3fe-4274-4143-b975-53ed31eacc3c	56538202-f648-47fd-b32d-cd451cd08bce	4	c. Sterilisasi regio terkait (5)	0	5	3	5	100	0	100	1	\N	\N	0	0	0	1	Persiapan (20)
461734dc-22c4-4281-af2b-82261103073b	56538202-f648-47fd-b32d-cd451cd08bce	5	Anestesi (30)	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	Anestesi (30)
84f33e1a-befd-46a7-b898-01a2e0ea2d1a	56538202-f648-47fd-b32d-cd451cd08bce	6	a. Anestesi topikal regio terkait (15)	0	15	9	15	100	0	100	1	\N	\N	0	0	0	2	Anestesi (30)
b1e17449-d090-4620-8f2b-be6fed9cdfad	56538202-f648-47fd-b32d-cd451cd08bce	6	b. Numbness (15)	0	15	9	15	100	0	100	1	\N	\N	0	0	0	2	Anestesi (30)
70d1e601-3e10-4cfa-8e45-16b6a0dbe58e	56538202-f648-47fd-b32d-cd451cd08bce	7	Teknik (50)	0	0	0	0	0	0	0	1	\N	\N	0	0	3	3	Teknik (50)
bad4f96b-ca39-429f-86cd-5c6293d36f39	56538202-f648-47fd-b32d-cd451cd08bce	8	a. Pencabutan gigi dengan forceps (30)	0	30	18	30	100	0	100	1	\N	\N	0	0	0	3	Teknik (50)
09f73ef0-4d24-481e-a050-53da05d78d36	56538202-f648-47fd-b32d-cd451cd08bce	9	b. Kontrol perdarahan (10)	0	10	6	10	100	0	100	1	\N	\N	0	0	0	3	Teknik (50)
0f4f29a6-e5f7-4b1e-b70e-f177ab11420a	56538202-f648-47fd-b32d-cd451cd08bce	10	c. Intruksi post ekstraksi dan pemberian obat (10) (6-10)	0	10	6	10	100	0	100	1	\N	\N	0	0	0	3	Teknik (50)
da054ee2-ed91-4aa8-9b10-473441593093	19633f89-3711-4827-9fc9-fdb49316e755	1	Data pasien	1	0	0	0	0	0	0	1	\N	2024-04-04 08:39:04	0	0	0	1	["kode_sub_name"]
eb89be64-2417-46b1-95cc-0c7483e9e605	19633f89-3711-4827-9fc9-fdb49316e755	3	Pemeriksaan KU, EO, IO	1	0	0	0	0	0	0	1	\N	\N	0	1	0	1	Indikasi dan Pengisian Status
d771af19-b69c-40e3-9939-d327ce0b8fe6	19633f89-3711-4827-9fc9-fdb49316e755	6	Pembuatan model studi	1	0	0	0	0	0	0	1	\N	\N	0	1	0	1	Indikasi dan Pengisian Status
30994d6f-28de-4ee9-a2bc-6bb6f0ccbd0d	19633f89-3711-4827-9fc9-fdb49316e755	5	Dokumentasi kondisi klinis awal	1	0	0	0	0	0	0	1	\N	\N	0	1	0	1	Indikasi dan Pengisian Status
29c3e582-6ae8-40db-a5e2-6bd34f63d4a4	19633f89-3711-4827-9fc9-fdb49316e755	2	Anamnesis	1	0	0	0	0	0	0	1	\N	\N	0	1	0	1	Indikasi dan Pengisian Status
a8cee5e1-d26e-498d-a7b6-f50a95d1aea3	19633f89-3711-4827-9fc9-fdb49316e755	7	Interpretasi radiografis	1	0	0	0	0	0	0	1	\N	2024-04-04 10:35:29	0	1	0	1	["kode_sub_name"]
5ddf0885-1e11-4538-a62d-ec5ffc17e5d7	19633f89-3711-4827-9fc9-fdb49316e755	5	Pencetakan anatomis RA dan RB	1	0	0	0	0	0	0	1	\N	\N	0	1	0	1	Indikasi dan Pengisian Status
19314b20-ff47-451a-8078-a09c561f99d3	19633f89-3711-4827-9fc9-fdb49316e755	4	Dokumentasi kondisi klinis awal	1	0	0	0	0	0	0	1	\N	\N	0	1	0	1	Indikasi dan Pengisian Status
4e57a362-9b65-4cb7-95f9-3a4c8522882b	19633f89-3711-4827-9fc9-fdb49316e755	8	Diagnosis	1	0	0	0	0	0	0	1	\N	\N	0	1	0	1	Indikasi dan Pengisian Status
c048cc8f-7966-4563-b0a1-f7d8c27678d0	19633f89-3711-4827-9fc9-fdb49316e755	9	Rencana perawatan	1	0	0	0	0	0	0	1	\N	\N	0	1	0	1	Indikasi dan Pengisian Status
735e385e-c1cc-45d5-8fa5-668299f0191c	19633f89-3711-4827-9fc9-fdb49316e755	0	Surveying, Blocking dan Preparasi Rest	0	0	0	0	0	0	0	1	\N	\N	0	0	2	2	Surveying, Blocking dan Preparasi Rest
847ca412-49a1-4e96-aad4-cac95fee9898	19633f89-3711-4827-9fc9-fdb49316e755	1	Surveying pada model RA dan RB	1	0	0	0	0	0	0	1	\N	\N	0	1	0	2	Surveying, Blocking dan Preparasi Rest
20bb2c23-d2c7-4f08-bbec-95de79a2d42e	19633f89-3711-4827-9fc9-fdb49316e755	2	Blocking undercut	1	0	0	0	0	0	0	1	\N	\N	0	1	0	2	Surveying, Blocking dan Preparasi Rest
58d24e1d-c66e-4448-ba34-f66971236ae2	19633f89-3711-4827-9fc9-fdb49316e755	3	Preparasi rest pada gigi penyangga	1	0	0	0	0	0	0	1	\N	\N	0	1	0	2	Surveying, Blocking dan Preparasi Rest
8505efdf-e1f3-42ce-a6ee-027d65df9bec	19633f89-3711-4827-9fc9-fdb49316e755	0	Individual Tray	0	0	0	0	0	0	0	1	\N	\N	0	0	3	3	Individual Tray
f0a71983-ec04-4842-a56a-33b53c8959c7	19633f89-3711-4827-9fc9-fdb49316e755	1	Menggambar outline form pada model RA dan RB (batas antara jaringan bergerak dan tidak bergerak	1	0	0	0	0	0	0	1	\N	\N	0	1	0	3	Individual Tray
57e6e03c-6da7-4b67-9c7a-dda1f6cc6601	19633f89-3711-4827-9fc9-fdb49316e755	2	Membuat lempeng malam merah 2mm diatas outline form	1	0	0	0	0	0	0	1	\N	\N	0	1	0	3	Individual Tray
ce454f49-4859-4ee8-a0ec-488e86b89900	19633f89-3711-4827-9fc9-fdb49316e755	3	Membuat stopper pada malam di daerah edentulous	1	0	0	0	0	0	0	1	\N	\N	0	1	0	3	Individual Tray
173b5598-7b45-4343-8c9d-cec1a9e662d2	19633f89-3711-4827-9fc9-fdb49316e755	4	Pembuatan sendok cetak perorangan dengan bahan self curing akrilik / blue ostron	1	0	0	0	0	0	0	1	\N	\N	0	1	0	3	Individual Tray
d8863f18-f993-472f-807d-149639eff865	19633f89-3711-4827-9fc9-fdb49316e755	0	Border Molding	0	0	0	0	0	0	0	1	\N	\N	0	0	4	4	Border Molding
eae12053-3643-4c38-9eb6-df92f9c4fc8f	19633f89-3711-4827-9fc9-fdb49316e755	1	Penyesuaian batas tepi sendok cetak perorangan RA / RB pada pasien	1	0	0	0	0	0	0	1	\N	\N	0	1	0	4	Border Molding
88dc2c3e-6513-4838-ab92-10490af02eec	19633f89-3711-4827-9fc9-fdb49316e755	2	Border molding RA / RB	3	0	0	0	0	0	0	1	\N	\N	0	3	0	4	Border Molding
465a43e2-6ef4-4396-8b4f-5f0bf6407747	19633f89-3711-4827-9fc9-fdb49316e755	0	Pencetakan Fungsional dan Pembuatan Model Kerja	0	0	0	0	0	0	0	1	\N	\N	0	0	5	5	Pencetakan Fungsional dan Pembuatan Model Kerja
61a0d043-6f34-4512-95f9-c95fa2974a71	19633f89-3711-4827-9fc9-fdb49316e755	1	Mencetak fungsional RA dan RB	1	0	0	0	0	0	0	1	\N	\N	0	1	0	5	Pencetakan Fungsional dan Pembuatan Model Kerja
8f1fe47b-7d9c-48ec-8e52-b5a0f7f054c4	19633f89-3711-4827-9fc9-fdb49316e755	2	Pembuatan model kerja RA dan RB	1	0	0	0	0	0	0	1	\N	\N	0	1	0	5	Pencetakan Fungsional dan Pembuatan Model Kerja
763f2c1f-028b-49e4-92c2-c1545e17023b	19633f89-3711-4827-9fc9-fdb49316e755	0	Pembuatan Lempeng, Galengan Gigit dan penetapan Gigit	0	0	0	0	0	0	0	1	\N	\N	0	0	6	6	Pembuatan Lempeng, Galengan Gigit dan penetapan Gigit
829d9379-2384-444d-92bb-40ba74708d78	19633f89-3711-4827-9fc9-fdb49316e755	1	Pembuatan Lempeng dan galengan gigit RA dan RB	1	0	0	0	0	0	0	1	\N	\N	0	1	0	6	Pembuatan Lempeng, Galengan Gigit dan penetapan Gigit
025efe83-4495-469d-a41f-0e2831d25f6b	19633f89-3711-4827-9fc9-fdb49316e755	2	Penetapan letak dan tinggi gigit	3	0	0	0	0	0	0	1	\N	\N	0	3	0	6	Pembuatan Lempeng, Galengan Gigit dan penetapan Gigit
bf0e80f8-9a38-4a99-8a04-25266c148ea8	19633f89-3711-4827-9fc9-fdb49316e755	0	Mounting Model, Pembuatan Klamer dan Penyusunan Gigi	0	0	0	0	0	0	0	1	\N	\N	0	0	7	7	Mounting Model, Pembuatan Klamer dan Penyusunan Gigi
5fdf51ed-449d-4e5f-a62f-4f9ed89e7c26	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	8	Jari pasien diarahkan untuk me-fiksasi film	2	0	0	0	0	0	0	1	\N	2024-04-23 20:04:46	0	2	0	1	["kode_sub_name"]
457aae28-a96e-4450-a471-10ff880dccc5	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	6	Mempersilahkan pasien duduk di alat xray\ndan memposisikan kepala pasien: \na. Kepala bersandar pada headrest \nb. Bidang sagital tegak lurus lantai\nc. Bidang oklusal sejajar dengan lantai	10	0	0	0	0	0	0	1	\N	2024-04-23 20:05:06	0	10	0	1	["kode_sub_name"]
e63c6735-4cde-4093-98cd-0b2822c924ce	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	5	Kerjasama	0	0	0	0	5-14	5	14	1	\N	2024-04-23 20:11:06	0	0	0	2	["kode_sub_name"]
8f9a5f01-1723-4f02-952a-45ffffd2b050	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	13	Mengeluarkan  fim  dari  mulut  pasien  dan mempersilahkan   pasien   berdiri,   melepas apron pelindung radiasi.	1	0	0	0	0	0	0	1	\N	2024-04-23 20:11:33	0	1	0	1	["kode_sub_name"]
b1bde434-acb3-4d0e-b5ea-f22e0b0940ef	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	1	Menerima dan membaca rujukan pemeriksaan  radiograf periapikal, melakukan informed consent pada pasien dan  menulis  pada  buku  catatan  di  ruang Xray	2	0	0	0	0	0	0	1	\N	2024-04-23 20:25:29	0	2	0	1	["kode_sub_name"]
\.


--
-- TOC entry 3708 (class 0 OID 16433)
-- Dependencies: 216
-- Data for Name: assesmentgroupfinals; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.assesmentgroupfinals (id, name, active, created_at, updated_at, specialistid, bobotvaluefinal) FROM stdin;
43f4c345-0ee5-4ab5-8b54-c264b812344b	PEKERJAAN KLINIK	1	\N	\N	\N	\N
c2e38b5a-87c1-4a94-8577-bb127bbee347	PEKERJAAN KLINIK PENAMBALAN	1	\N	\N	\N	\N
bf11ae27-2603-488e-a244-8deea2056f51	PEKERJAAN KLINIK PENCABUTAN	1	\N	\N	\N	\N
a2c66747-7ed0-4ed9-bc98-9773d2a8c963	DOPS	1	\N	\N	\N	\N
49df6af1-107f-4379-bdb9-df2725ed5960	UJIAN BAGIAN	1	\N	\N	\N	\N
7c1d1dcb-9cc1-44e9-93a6-5c9ea028e07b	LAPORAN KHUSUS	1	\N	\N	\N	\N
83921a16-54e2-484d-b85a-ecedb843ed57	PEKERJAAN KLINIK - ORTHO	1	\N	\N	4b5ca39c-5a37-46d1-8198-3fe2202775a2	95
2cf2154b-f35f-4273-89dc-b63d89313856	LAPORAN KASUS - ORTHO	1	\N	\N	4b5ca39c-5a37-46d1-8198-3fe2202775a2	5
d07c0b27-d25f-4c82-b413-ad0333018261	SEMINAR KASUS	1	\N	2024-03-06 08:47:08	\N	\N
b1d35478-44d6-40b9-8655-a4454933c740	KONSERVASI NILAI	0	\N	2024-03-06 08:49:55	ea766055-8238-4c7d-9c1a-2f5244ca15f3	50
111ef506-2cdf-4a05-aa96-48e586e8f09a	PEKERJAAN KLINIK - PERIO	1	\N	2024-03-06 09:54:21	88e2a725-abb3-459d-99dc-69a43a39d504	65
760b0b03-3a83-48b8-9ed7-b47b5ef290f1	DISKUSI KHUSUS - PERIO	1	\N	\N	88e2a725-abb3-459d-99dc-69a43a39d504	20
ed7bbb22-f441-45cd-b20c-299506c86918	DOPS - PERIO	1	\N	\N	88e2a725-abb3-459d-99dc-69a43a39d504	15
b2993f96-fe1c-443d-b655-c61ea86ec9b3	PEKERJAAN KLINIK PEMERIKSAAN - PEDO	1	\N	\N	5756d1b9-34b4-4d49-b5fb-76b68bbd736e	30
45e80887-879c-463f-8d51-f4850df09bc3	PEKERJAAN KLINIK PENAMBALAN - PEDO	1	\N	\N	5756d1b9-34b4-4d49-b5fb-76b68bbd736e	40
98ce60b4-9be2-4d21-b879-7b0887674d3d	PEKERJAAN KLINIK PENCABUTAN - PEDO	1	\N	\N	5756d1b9-34b4-4d49-b5fb-76b68bbd736e	30
51c0074b-95a0-4612-b36d-a5d160fcc42b	PEKERJAAN KLINIK - RADIOLOGI	1	\N	\N	cf504bf3-803c-432c-afe1-d718824359d5	60
49d17b50-782c-48af-bf77-b23aa2521a33	PENILAIAN PROSESING FILM RONGTEN DIGITAL (1)	0	\N	2024-04-01 10:02:26	cf504bf3-803c-432c-afe1-d718824359d5	80
49f20cd5-0ed3-4f3c-85a2-091ec3a9c2e4	DOPS - RADIOLOGI	1	\N	\N	cf504bf3-803c-432c-afe1-d718824359d5	10
6456b43f-f3da-4a19-8797-a17085a6f2bb	JOURNAL READING - RADIOLOGI	1	\N	2024-04-01 13:47:06	cf504bf3-803c-432c-afe1-d718824359d5	10
516e0fd2-3617-4214-828b-aa54ec14d557	-	0	\N	2024-04-01 13:47:43	cf504bf3-803c-432c-afe1-d718824359d5	10
\.


--
-- TOC entry 3709 (class 0 OID 16438)
-- Dependencies: 217
-- Data for Name: assesmentgroups; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.assesmentgroups (id, specialistid, assementgroupname, type, active, created_at, updated_at, valuetotal, isskala, idassesmentgroupfinal, bobotprosenfinal) FROM stdin;
2feb22f2-f122-4cf2-9ada-6238d4369a18	4b5ca39c-5a37-46d1-8198-3fe2202775a2	DIAGNOSIS, ETIOLOGI DAN RENCANA PERAWATAN	1	1	\N	2024-03-05 15:40:45	40	0	83921a16-54e2-484d-b85a-ecedb843ed57	8
c1ff27fa-7779-4167-ba79-b55253758f95	4b5ca39c-5a37-46d1-8198-3fe2202775a2	INSERSI ALAT ORTODONTI LEPASAN	1	1	\N	2024-03-05 15:41:09	40	0	83921a16-54e2-484d-b85a-ecedb843ed57	5
1ec61be0-561e-45d9-ab6e-0af6159afe28	add71909-11e5-4adb-ab6e-919444d4aab7	terserah	4	1	\N	\N	100	1	43f4c345-0ee5-4ab5-8b54-c264b812344b	\N
352f12bb-e8b9-4986-83cd-bfc882379632	4b5ca39c-5a37-46d1-8198-3fe2202775a2	AKTIVASI ALAT ORTODONTI	1	1	\N	2024-03-05 15:41:28	40	0	83921a16-54e2-484d-b85a-ecedb843ed57	7
c844e587-0cff-487a-a81f-b5406215a1e8	add71909-11e5-4adb-ab6e-919444d4aab7	TUMPATAN KOMPOSIT KLAS I	4	1	\N	2024-03-05 15:35:36	100	1	43f4c345-0ee5-4ab5-8b54-c264b812344b	20
061105f4-25d6-4def-9849-07f2c521f33d	add71909-11e5-4adb-ab6e-919444d4aab7	TUMPATAN KOMPOSIT KLAS II	4	1	\N	2024-03-05 15:36:18	100	1	43f4c345-0ee5-4ab5-8b54-c264b812344b	25
596b9232-d58b-4f11-83ca-5afe81fce60c	add71909-11e5-4adb-ab6e-919444d4aab7	TUMPATAN KOMPOSIT KLAS III	4	1	\N	2024-03-05 15:36:29	100	1	43f4c345-0ee5-4ab5-8b54-c264b812344b	15
ead3749e-9673-442a-b817-221df6d8e3c6	add71909-11e5-4adb-ab6e-919444d4aab7	TUMPATAN KOMPOSIT KLAS IV	4	1	\N	2024-03-05 15:36:43	100	1	43f4c345-0ee5-4ab5-8b54-c264b812344b	25
23cb5164-8204-44be-ba28-e39ffe2cdb1f	add71909-11e5-4adb-ab6e-919444d4aab7	TUMPATAN GIC KLAS V	4	1	\N	2024-03-05 15:36:58	100	1	43f4c345-0ee5-4ab5-8b54-c264b812344b	15
19633f89-3711-4827-9fc9-fdb49316e755	a89710d5-0c4c-4823-9932-18ce001d71a5	Gigi Tiruan Sebagian Lepasan	1	1	\N	\N	0	0	43f4c345-0ee5-4ab5-8b54-c264b812344b	75
48f68e47-a864-4aa8-89b7-b73faccd5f22	a89710d5-0c4c-4823-9932-18ce001d71a5	PENYAJI DISKUSI KASUS GIGI TIRUAN SEBAGIAN LEPASAN	1	1	\N	\N	0	0	43f4c345-0ee5-4ab5-8b54-c264b812344b	10
15435521-7e66-45bb-9a29-1ed297ef1413	a89710d5-0c4c-4823-9932-18ce001d71a5	DOPS MENCETAK FUNGSIONAL	1	1	\N	\N	0	0	43f4c345-0ee5-4ab5-8b54-c264b812344b	15
22a0e98a-a096-4bef-880b-e94e81429241	4b5ca39c-5a37-46d1-8198-3fe2202775a2	ANAMNESIS	1	1	\N	2024-03-05 15:37:33	40	0	83921a16-54e2-484d-b85a-ecedb843ed57	4
90ce231f-a7ab-4e48-9b4d-5823e8314175	4b5ca39c-5a37-46d1-8198-3fe2202775a2	PEMERIKSAAN EO DAN IO, FOTO WAJAH DAN FOTO IO	1	1	\N	2024-03-05 15:38:15	40	0	83921a16-54e2-484d-b85a-ecedb843ed57	8
06ce9f8a-dc32-4798-99f8-512104e411a0	4b5ca39c-5a37-46d1-8198-3fe2202775a2	MENCETAK RAHANG ATAS DAN MENCETAK RAHANG BAWAH	1	1	\N	2024-03-05 15:38:34	40	0	83921a16-54e2-484d-b85a-ecedb843ed57	8
5e362dfd-6121-4041-a98a-f21dd06441de	4b5ca39c-5a37-46d1-8198-3fe2202775a2	MEMBUAT MODEL STUDI 1 DAN MODEL KERJA	1	1	\N	2024-03-05 15:39:04	40	0	83921a16-54e2-484d-b85a-ecedb843ed57	9
60ddaea5-aec0-4965-9c76-00f0080a5790	4b5ca39c-5a37-46d1-8198-3fe2202775a2	ANALISIS MODEL	1	1	\N	2024-03-05 15:39:50	40	0	83921a16-54e2-484d-b85a-ecedb843ed57	15
3b025e64-cedc-4ac2-b2ec-8f44ba46e89a	4b5ca39c-5a37-46d1-8198-3fe2202775a2	ANALISIS SEFALOMETRI	1	1	\N	2024-03-05 15:40:07	40	0	83921a16-54e2-484d-b85a-ecedb843ed57	12
2d589f54-d525-4de1-bf7a-92dddda02e4c	4b5ca39c-5a37-46d1-8198-3fe2202775a2	FOTOGRAFI EKSTRA ORAL DAN INTRA ORAL	1	1	\N	2024-03-05 15:40:26	40	0	83921a16-54e2-484d-b85a-ecedb843ed57	3
832939f0-0ace-4fd3-89aa-e659550f041e	4b5ca39c-5a37-46d1-8198-3fe2202775a2	KONTROL	6	1	\N	2024-03-05 15:41:42	0	0	83921a16-54e2-484d-b85a-ecedb843ed57	6
5f1bf278-5507-418a-8def-8d9f0c5709d8	4b5ca39c-5a37-46d1-8198-3fe2202775a2	MODEL STUDI 2	1	1	\N	2024-03-05 15:42:00	40	0	83921a16-54e2-484d-b85a-ecedb843ed57	5
0bb1d8ea-3074-42bb-af7b-cb40db0e62f2	4b5ca39c-5a37-46d1-8198-3fe2202775a2	PENILAIAN HASIL PERAWATAN	7	1	\N	2024-03-05 15:42:24	0	0	83921a16-54e2-484d-b85a-ecedb843ed57	5
a5cb8841-1d03-4102-918f-5a8b7e3456fd	4b5ca39c-5a37-46d1-8198-3fe2202775a2	PENYAJI LAPORAN KASUS	1	1	\N	2024-03-05 15:42:59	40	0	2cf2154b-f35f-4273-89dc-b63d89313856	5
1834e4f8-5cdf-4d95-b956-6432c52c61ff	88e2a725-abb3-459d-99dc-69a43a39d504	Anamnesis dan Pengisian Status+ USS+kontrol	5	1	\N	\N	100	0	111ef506-2cdf-4a05-aa96-48e586e8f09a	15
5fbd8999-a81d-4ee4-b3e3-e522c81c8b76	88e2a725-abb3-459d-99dc-69a43a39d504	USS+kontrol+ desensitisasi+kontrol	5	1	\N	\N	100	0	111ef506-2cdf-4a05-aa96-48e586e8f09a	20
dbfd2b30-3f6e-43da-92ad-2866d5ba4386	88e2a725-abb3-459d-99dc-69a43a39d504	Splinting fiber	5	1	\N	\N	100	0	111ef506-2cdf-4a05-aa96-48e586e8f09a	15
3ed4849a-e795-4eb9-98b0-059f851bd273	88e2a725-abb3-459d-99dc-69a43a39d504	Diskusi Tatap Muka/penyaji diskusi (Kasus Desentisisasi)	5	1	\N	\N	100	0	760b0b03-3a83-48b8-9ed7-b47b5ef290f1	20
b88f27a2-3e95-4544-b4cb-045e18904feb	88e2a725-abb3-459d-99dc-69a43a39d504	DOPS scaling manual + kontrol	5	1	\N	\N	100	0	ed7bbb22-f441-45cd-b20c-299506c86918	15
36da7989-cedc-49c4-82e1-aabead99a6c2	88e2a725-abb3-459d-99dc-69a43a39d504	Anamnesis dan Pengisian Status+ Scaling manual+kontrol	5	1	\N	2024-03-06 11:10:06	40	0	111ef506-2cdf-4a05-aa96-48e586e8f09a	15
4f078342-5e30-4774-abec-97a9d1c5abe9	5756d1b9-34b4-4d49-b5fb-76b68bbd736e	Prosedur Perawatan Penumpatan  Glass Ionomer Cement (GIC) / Resin  Komposit Kls II	3	1	\N	\N	100	1	b2993f96-fe1c-443d-b655-c61ea86ec9b3	10
a7a33913-a538-4c67-b755-5ee038e5c2d0	5756d1b9-34b4-4d49-b5fb-76b68bbd736e	Prosedur Pengisian Rekam Medik	3	1	\N	2024-04-03 15:21:43	100	1	b2993f96-fe1c-443d-b655-c61ea86ec9b3	10
15b9c6b5-1016-45fa-9156-7530d932d311	5756d1b9-34b4-4d49-b5fb-76b68bbd736e	Prosedur Dental Health Education	3	1	\N	2024-04-03 15:33:04	100	1	b2993f96-fe1c-443d-b655-c61ea86ec9b3	5
a5f134ca-c412-431f-99a8-79ed079d2956	5756d1b9-34b4-4d49-b5fb-76b68bbd736e	Prosedur Perawatan Fissure Sealant	3	1	\N	\N	100	1	b2993f96-fe1c-443d-b655-c61ea86ec9b3	50
4c58ddcf-c320-4bc3-b43a-e899997e48f6	5756d1b9-34b4-4d49-b5fb-76b68bbd736e	Prosedur Perawatan Preventive Adhesive Restoration	3	1	\N	\N	100	1	b2993f96-fe1c-443d-b655-c61ea86ec9b3	5
3fe495a9-74b4-4606-a185-9f5c056033f6	5756d1b9-34b4-4d49-b5fb-76b68bbd736e	Prosedur Perawatan Penumpatan  Glass Ionomer Cement (GIC) / Resin  Komposit Kls I	3	1	\N	2024-04-03 16:00:03	100	1	b2993f96-fe1c-443d-b655-c61ea86ec9b3	10
4f8d29e6-8a8b-49e1-bd75-f295dc94ac0a	5756d1b9-34b4-4d49-b5fb-76b68bbd736e	Prosedur Perawatan Penumpatan Glass Ionomer Cement (GIC) / Resin Komposit Kls III	3	1	\N	\N	100	1	b2993f96-fe1c-443d-b655-c61ea86ec9b3	5
b131b399-9b47-4b91-8504-d8047c6b3576	5756d1b9-34b4-4d49-b5fb-76b68bbd736e	Prosedur Perawatan Penumpatan  Glass Ionomer Cement (GIC) / Resin  Komposit Kls V	3	1	\N	\N	100	1	b2993f96-fe1c-443d-b655-c61ea86ec9b3	5
56538202-f648-47fd-b32d-cd451cd08bce	5756d1b9-34b4-4d49-b5fb-76b68bbd736e	Prosedur Pencabutan Gigi Sulung / Prosedur Pencabutan Gigi Sulung dengan Anastesi Infiltrasi Tanpa Penyulit dengan Anastesi Topikal	3	1	\N	\N	100	1	b2993f96-fe1c-443d-b655-c61ea86ec9b3	15
4446af12-f58b-4c5f-ae83-f21f880733ca	cf504bf3-803c-432c-afe1-d718824359d5	TEKNIK RADIOGRAFI INTRAORAL PERIAPIKAL (2)	1	0	\N	2024-04-04 10:24:44	80	0	51c0074b-95a0-4612-b36d-a5d160fcc42b	80
608ea017-a9c9-4c54-9870-d82ad90c868e	cf504bf3-803c-432c-afe1-d718824359d5	INTERPRETASI RADIOGRAF INTRAORAL (2)	1	0	\N	2024-04-04 10:24:50	100	0	51c0074b-95a0-4612-b36d-a5d160fcc42b	100
01977c96-2356-488f-a656-10ddc52fd53c	cf504bf3-803c-432c-afe1-d718824359d5	PENILAIAN PROSESING FILM RONTGEN  (2)	1	0	\N	2024-04-04 10:24:35	80	0	51c0074b-95a0-4612-b36d-a5d160fcc42b	\N
16e7fcab-101f-498c-8989-062ec832c8b8	cf504bf3-803c-432c-afe1-d718824359d5	PENILAIAN PROSESING FILM RONGTEN DIGITAL	1	1	\N	2024-04-23 19:13:11	80	0	51c0074b-95a0-4612-b36d-a5d160fcc42b	5
79d64714-b496-414a-a28c-5cfd319280e9	cf504bf3-803c-432c-afe1-d718824359d5	INTERPRETASI RADIOGRAF OKLUSAL	1	1	\N	2024-04-23 19:13:18	80	0	51c0074b-95a0-4612-b36d-a5d160fcc42b	5
36e976a1-7b53-4d82-a025-72c3de4e1ed9	cf504bf3-803c-432c-afe1-d718824359d5	TEKNIK RADIOGRAFI INTRAORAL PERIAPIKAL	1	1	\N	2024-04-23 19:13:02	80	0	51c0074b-95a0-4612-b36d-a5d160fcc42b	5
27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	cf504bf3-803c-432c-afe1-d718824359d5	DOPS	1	1	\N	2024-04-23 19:59:17	100	0	49f20cd5-0ed3-4f3c-85a2-091ec3a9c2e4	10
8f01380d-cf81-4e20-9fb1-6e416b18ab5a	cf504bf3-803c-432c-afe1-d718824359d5	PENYAJI JR	1	1	\N	2024-04-23 19:12:44	80	0	6456b43f-f3da-4a19-8797-a17085a6f2bb	10
18ba4183-db88-4de8-af99-6dd83d9b075d	cf504bf3-803c-432c-afe1-d718824359d5	Radiografi Intraoral Periapikal	1	1	\N	2024-04-23 19:12:28	100	0	49f20cd5-0ed3-4f3c-85a2-091ec3a9c2e4	5
700d3334-6b14-4b7a-8973-dc0470f55c51	cf504bf3-803c-432c-afe1-d718824359d5	VIDEO TEKNIK RADIOGRAFI INTRAORAL PERIAPIKAL	1	1	\N	2024-04-23 19:12:33	80	0	51c0074b-95a0-4612-b36d-a5d160fcc42b	5
97e25278-15f0-4436-9413-548ddb1edac2	cf504bf3-803c-432c-afe1-d718824359d5	INTERPRETASI RADIOGRAF INTRAORAL	1	1	\N	2024-04-23 19:12:57	100	0	51c0074b-95a0-4612-b36d-a5d160fcc42b	5
2569196c-7dfd-4ab3-9845-0cc1fe7fc1e9	cf504bf3-803c-432c-afe1-d718824359d5	LEMBAR  INTERPRETASI EKSTRAORAL	1	1	\N	2024-04-23 19:13:23	80	0	51c0074b-95a0-4612-b36d-a5d160fcc42b	5
\.


--
-- TOC entry 3710 (class 0 OID 16444)
-- Dependencies: 218
-- Data for Name: emrkonservasi_jobs; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.emrkonservasi_jobs (id, datejob, keadaangigi, tindakan, keterangan, user_entry, user_entry_name, user_verify, user_verify_name, created_at, updated_at, idemr, active, date_verify) FROM stdin;
83a40477-61b4-4435-8f28-4a2ddb2aa17e	2024-04-02 15:35:45	fgdfg	dfhfdh	sfsdf	4122023034	Jessica Putri Souisa	\N	\N	\N	\N	a4b1dc37-5371-4afe-84b1-3f606e5fdb08	1	\N
b5ee82bb-9554-4f05-b739-7f93586eaeef	2024-04-02 15:35:53	qwe	erwe	saf	4122023034	Jessica Putri Souisa	\N	\N	\N	\N	a4b1dc37-5371-4afe-84b1-3f606e5fdb08	1	\N
c660a67a-ca9f-45aa-b93a-ec95f09c428b	2024-04-02 15:35:30	sapik	ds	sds	4122023034	Jessica Putri Souisa	\N	\N	\N	2024-04-02 15:36:05	a4b1dc37-5371-4afe-84b1-3f606e5fdb08	1	\N
aac3c945-7141-4ec7-91fa-5a2bb91b91f1	2024-04-03 13:03:00	sasa	qweq	wewr	4122023034	Jessica Putri Souisa	\N	\N	\N	\N	1c978704-da00-4ca8-8baf-f831a83d4adf	1	\N
620ce3a1-5ee8-42ed-9fe9-ee3192a118bc	2024-04-03 13:03:08	sdf	fgfh	hjgh	4122023034	Jessica Putri Souisa	\N	\N	\N	\N	1c978704-da00-4ca8-8baf-f831a83d4adf	1	\N
53ec5f5e-5da3-4e6e-b7c1-1df52cc67065	2024-04-03 13:03:16	ert	rty	tyu	4122023034	Jessica Putri Souisa	\N	\N	\N	\N	1c978704-da00-4ca8-8baf-f831a83d4adf	1	\N
92dce11b-879c-45c4-b712-86b079894f09	2024-04-23 15:09:02	gnjvbg jcmb gkmh khjglk hkhkhfgkfh51hf65h6fh25f2652h526gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg999999999999999999999	hkhgf khfkhjlgjl.jkl.k;.h v  fhngfhnf jkmhjf gh fjghfxf6h65f5h25f2h25f5353gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg66666666666666666666666666666666666666666666666	gjnfchjdfgdfsghdfghdfghbdfghbfhnfhdhj51h5f151hff353.5243.hggggggggggggggggggggggggggggggggggggggggggggggggggg5555555555555555555555555555555555	4122023041	Qanita Regina Maharani	\N	\N	\N	2024-04-23 15:09:27	af2b6ef0-2870-4e4f-bd29-9e072eb853b5	1	\N
eb1a0c15-46d1-469e-9451-1a5e7d32d577	2024-05-27 08:35:56	Gigi 45 berlubang	S: Gigi belakanh bawah kanan berlubang tidak terasa sakit\nO: Gigi 45 Pn D3 (1,1)\nA: Pulpa normal\nDD: Pulpitis reversibel\nP: Penambalan rk kelas 1	-	4122023035	Jihan Ar Rohim	\N	\N	\N	2024-05-27 08:36:14	1107fa0d-6be3-4dfa-ae05-b404ba0af3c2	0	\N
ed9ca8f3-a459-4e6d-ad91-38982790518a	2024-05-27 08:38:13	Gigi 45 berlubang	S: Gigi belakanh bawah kanan berlubang tidak terasa sakit\nO: Gigi 45 PN D3 (1,1)\nA: Pulpa normal\nDD: Pulpitis normal\nP: Penambalan RK kelas 1	Konsultasi pada tgl 13 maret 2024	4122023035	Jihan Ar Rohim	\N	\N	\N	\N	1107fa0d-6be3-4dfa-ae05-b404ba0af3c2	1	\N
1864d877-57ca-4c82-91ec-2b3d519fcff6	2024-05-27 08:50:48	Gigi 11 berlubang	S: Gigi depan atas kanan berlubang, tidak terasa sakit\nO: Gigi 11 PN D3 (1,1)\nA: Pulpa normal\nDD: Pulpitis reversibel\nP: Penambalan RK kelas 3	Kontrol pada 8 maret 2024	4122023035	Jihan Ar Rohim	\N	\N	\N	\N	b76230ab-79a6-4829-8d34-86fd808c959f	1	\N
3e2dbd6c-17ff-4d65-8aa2-e1234db99eba	2024-05-27 09:17:25	Gigi 35 berlubang	S: Gigi kiri bawah belakang berlubang\nO: Gigi PN D3 (2,1)\nA: Pulpa normal\nDD: pulpitis reversibel\nP: Penambaklas RK kelas 2	kontrol 21 Maret 2024	4122023035	Jihan Ar Rohim	\N	\N	\N	\N	8d62211f-32d6-46d9-8846-ce0c87036157	1	\N
a8e96a60-8237-4eb7-96ab-954830ca6ddc	2024-05-27 09:30:32	gigi 45	S = gigi bawah kanan pasien berlubang dan pasien tidak merasakan sakit \nO = gigi 45 PN \nA = pulpa normal \nDD = pulpitis reversible \nP = penambalan RK kelas 1\n1. preparasi resin komposit \n2. etsa \n3. bonding \n4. penambalan RK kelas 1 \n5. poleshing\n- kontrol	penambalan : 3/5/24\nkontrol : 13/5/24	4122023027	Atika Rahma Minabari	\N	\N	\N	\N	f198d1d5-06df-4c60-9439-1b4f6969f304	1	\N
5f021313-c042-4d42-af8c-e482792095d8	2024-05-27 09:38:09	Gigi 11 fraktur insisal	S: Gigi depan atas patas sampai insisal\nO: Gigi 11 PN D3 (2,1)\nA: Pulpa norma;\nDD: Pulpitis reversibel\nP: Restorasi RK kelas 4\n\nKontrol tambalan kelas 4	Restorasi tgl 28 februari 2024\nKontrol 1 maret 2024	4122023035	Jihan Ar Rohim	\N	\N	\N	\N	fb19fecd-0968-4277-81a8-98e830e075f9	1	\N
11802336-7c69-456e-a5d6-d6fe8f041be4	2024-05-27 09:52:28	Gigi 23 berlubang	S: Gigi depan kiri atas berlubang, tidak terasa sakit\nO: Gigi 23 PN D3 (3,1)\nA: Pulpa normal\nDD: Pulpitis reversibel\nP: Restorasi kelas GIC kelas 5\n\nPoles dan Kontrol tambalan	Restorasi tgl 22 maret 2024\nKontroil tgl 26 maret 2024	4122023035	Jihan Ar Rohim	\N	\N	\N	\N	08a54fdf-be1c-415f-b961-78faf3e7c33f	1	\N
4ba6a086-2fac-4096-a1be-c9c693ee9096	2024-05-27 10:23:39	gigi 11 fraktur insisal	Kontrol resin komposit kelas 4\n1. tumpatan baik\n2. tumpatan sudah bisa dipakai makan \n3. tidak ada sakit	-	4122023044	Sekar Decita Ananda Iswanti	\N	\N	\N	2024-05-27 10:25:04	7b61ce0e-7924-47b2-a6fc-de39f781570a	1	\N
62524c1d-56df-408d-8064-6f4403b52c3c	2024-05-27 10:30:55	gigi 11 : fraktur insisal	S: gigi kanan atas depan patah akibat jatuh\nO: gigi 11 (fraktur insisal)\nA: pulpa normal (DD: pulpitis reversible)\nP: penambalan resin komposit kelas 4\n1. preparasi\n2. etsa\n3. bonding\n4. penambalan 3M ESPE Filtek Z350 Xt A2\n5. poles	-	4122023044	Sekar Decita Ananda Iswanti	\N	\N	\N	\N	0215cb9d-97f5-48b6-9532-20b639e11955	1	\N
a3043575-3b23-4922-9007-2c39c3c790c0	2024-05-27 10:42:48	Gigi 14 berlubang	preparasi kelas v, the, restores GIC A3	S= Gigi belakang kanan atas berlubang dan tidak ada rasa sakit\nO= Gigi 14 PN D3(3,1)\nA= Pulpa normal\n  DD= pulpits reversibel\nP= Penambalan GIC kelas V\n1.Isolasi Daerah kerja\n2. pembersihan Daerah yang terkena karies\n3.persiapan GIC dan manipulation GIC\n4.penambalan kelas V\n5. counturing\n6. finishing\n7. polishing	4122023038	Laras Fajri Nanda Widiiswa	\N	\N	\N	\N	ad454423-6988-4fdc-83cf-a6a303e5378c	1	\N
73aa629a-78ed-491c-b569-788e7935fb4b	2024-05-27 10:46:00	gigi 46	Kontrol :\n1. tumpatan baik\n2. pasien tidak merasa sakit\n3. gigi yang dilakukan penumpatan dapat dipakai makan dengan baik	-	4122023044	Sekar Decita Ananda Iswanti	\N	\N	\N	\N	2afe0215-6bdc-44fe-b3ab-0cf034808c26	1	\N
b9993b2c-7169-4df8-b2cd-400b4200b570	2024-05-27 10:50:40	Gigi 14 berlubang	poles dan kontrol	poles dan kontrol	4122023038	Laras Fajri Nanda Widiiswa	\N	\N	\N	\N	4ecf16ee-528f-408d-9c33-de5b7057f143	1	\N
7f321a90-5e5d-47ec-8b0e-44281f3dd406	2024-05-27 11:00:33	gigi 11 berlubang	Composite kelas 3	S=gigi depan kanan atas berlubang\nO=gigi 11 PR D4(2,2)\nA=Pulpa normal\n    DD= pulpa reversibel\nP=Penambalan composite \n1.isolasi daerah kerja\n2.pembersihan daerah kavitas\n3.preparasi kelas 3\n4. etsa\n5. bonding\n6. curing\n7. menggunakan strip matrix\n8.composite warna A3\n9. curing\n10. counturing\n11. finishing\n12. polishing	4122023038	Laras Fajri Nanda Widiiswa	\N	\N	\N	\N	00fd1210-de37-4b52-871b-a0d1ab771c2b	1	\N
6fd20e27-a644-47ab-be6c-4a8c55608540	2024-05-27 11:07:22	gigi 11 berlubang	kontrol	kontrol	4122023038	Laras Fajri Nanda Widiiswa	\N	\N	\N	\N	78472c28-8618-42e6-b620-d9674f2a242a	1	\N
7ab226a9-5f60-4cda-a5df-dc4527dfd247	2024-05-27 12:21:31	gigi 45 berlubang	S: Gigi belakang bawah kanan berlubang\nO: Gigi 45 D3 (1,1)\nA: Diagnosa = Pulpa normal\nDD= Pulpitis reversibel\nP: Pro restorasi klas 1 RK\nTahapan :\n1. Pembersihan gigi 45 dengan pumice\n2. Pemilihan warna gigi 45 \n3. Preparasi gigi 45 dengan modifikasi preparation\n4. Aplikasi etsa 15s\n5. Aplikasi bonding gen 7 20s\n6. Penambalan gigi 45 RK 3M Filtek Z350 Xt A3\n7. Finishing\n8. Polishing\n\nKontrol seminggu setelahnya\ninstruksi setelah penambalan :\n1. Jika tambalan lepas segera ke klinik terdekat\n2. Tidak makan dan minum yang panas ataupun dingin\n3. Tidak menggosok gigi terlalu keras	-	4122023030	Faika Zahra Chairunnisa	\N	\N	\N	\N	a51f1eb8-dc49-4c16-b9ce-badffc63b499	1	\N
f3e7868e-c46f-43fb-b699-797f82279e14	2024-05-27 12:55:50	Gigi 24 berlubang	S: gigi belakang kiri atas berlubang dan tidak ada rasa sakit \nO: Gigi 24 D3 (3,1)\nA: Pulpa normal \nP: Restorasi GIC kelas V \n- Isolasi daerah kerja \n- preparasi kelas V \n- persiapan dan manipulasi GIC \n- Aplikasi dentin conditioner dan keringkan \n- penambalan GIC kelas V \n- konturing, finishing, dan poles	dilakukan kontrol penambalan pada tanggal 25 maret	4122023041	Qanita Regina Maharani	\N	\N	\N	\N	a375ec7a-17d1-46b2-a17d-eb732c878be1	1	\N
e7c2caa5-b39b-4382-98ce-9d36c0dab82a	2024-05-27 13:07:44	Gigi 15 berlubang	S: Gigi belakang atas kanan berlubang\nO: Gigi 15 D4 (3,2)\nA: Diagnosis = Pulpa normal\nDD= Pulpitis reversibel\nP: Pro restorasi klas V GIC\nTahapan:\n1. Pembersihan gigi\n2. Pemilihan warna gigi\n3. Preparsi gigi\n4. Aplikasi dentin kondisioner 10s\n5. Tumpat GIC A2\n6. Poles\n\nKontrol:minimal h+1pasca tambalan\ninstruksi :\n1. Tidak menyikat gigi dengan keras\n2. jika tambalan copot segera ke klinik terdekat\n3. Tidak makan/minum yang berwarna	-	4122023030	Faika Zahra Chairunnisa	\N	\N	\N	\N	6dfb7ea4-3f41-4c82-b66b-9832d8ea20af	1	\N
59cd47dd-ba9f-4ad5-992c-79e9d9ad9905	2024-05-27 13:24:55	Gigi 24 berlubang	S: Gigi belakang atas kiri berlubang\nO: Gigi 24 D4 (2,2)\nA: Diagnosis = Pulpitis normal\nDD= Pulpitis reversibel\nP: Pro restorasi RK klas 2\nTahapan:\n1. Pembersihan gigi\n2. Pemilihan warna gigi\n3. Preparasi gigi\n4. Aplikasi etsa\n5. Aplikasi bonding\n6. Penambalan gigi\n7. Finishing dan polishing\n\nKontrol : h+1 tambalan\ninstruksi :\n1. Jika tambalan lepas segera ke klinik terdekat\n2. Tidak memakan atau minum yang berwarna\n3. Tidak memakan makanan yang keras	-	4122023030	Faika Zahra Chairunnisa	\N	\N	\N	\N	f617ab22-6326-4485-9a54-7763b1e2f14b	1	\N
5039a28b-a204-43b6-a1c9-1a044e363a55	2024-05-27 13:25:41	36 D4 3,2\n37 D4 3,1	- PEMERIKSAAN LENGKAP\n- PENGISISAN STATUS DAN ACC PASIEN\n- PREPARASI KELAS 5 DAN RESTORASI GIC\n- S: GIGI BELAKANG KIRI BERLUBANG DAN TIDAK ADA RASA SAKIT\n- O: GIGI 36 PN D4 3,2\n- A: PULPA NORMAL /DD PULPITIS REVERSIBEL\n- P: 1. PEMBERSIHAN DAERAH SEKITAR \n2. PREPARASI KELAS V\n3. PERSIAPAN GIC A3\n4. PENAMBALAN KELAS V GIC DENGAN PLASTIC FILLING\n5. COUNTURING\n6. FINISHING\n7. POLESHING	-	4122023043	Sahri Muhamad Risky	\N	\N	\N	\N	9e2307e4-dbb5-4f8d-8c31-cb8ca41f8f34	1	\N
1e4c46e5-9c6a-4c53-920c-e706d6964424	2024-05-27 13:33:41	Gigi 12	S: Gigi depan atas kanan berlubang\nO: Gigi 12 D4 (2,2)\nA: Diagnosis = Pulpa normal\nDD= Pulpitis reversibel\nP: Pro restorasi RK klas 3\nTahapan:\n1. Pembersihan gigi\n2. Pemilihan warna gigi\n3. Preparasi gigi\n4. Aplikasi etsa\n5. Aplikasi bonding\n6. Penambalan gigi\n7. Finishing dan polishing\n\ninstruksi :\n1. Jika tambalan lepas segera ke klinik terdekat\n2. Tidak memakan atau minum yang berwarna\n3. Tidak memakan makanan yang keras\n\nKontrol : h+1 tambalan\n1. Tidak ada yang mengganjal\n2. Tidak ada perubahan warna\n3. Tidak kasar\n4. ngilu jika menggigit\n\nSaran : PSA dan OHIS ditingkatkan	-	4122023030	Faika Zahra Chairunnisa	\N	\N	\N	\N	a5801a7c-da27-4277-9855-f251f5a98141	1	\N
beb3ccb0-abe5-4599-9d67-f21507331be5	2024-05-27 13:38:48	46 D4 1,2	- PEMERIKSAAN LENGKAP\n- PENGISISAN STATUS DAN ACC PASIEN\n- PREPARASI KELAS 5 DAN RESTORASI GIC\n- S: GIGI BELAKANG KANAN BERLUBANG DAN TIDAK ADA RASA SAKIT\n- O: GIGI 46 PN D4 1,2\n- A: PULPA NORMAL /DD PULPITIS REVERSIBEL\n- P: 1. PEMBERSIHAN DAERAH SEKITAR \n2. ISOLASI DAERAH KERJA \n3. PREPARASI KELAS 1\n4. ETSA 10 DETIK\n5. BILAS ETSA\n6. APLIKASIKAN BONDING DENGAN MICROBRUSH\n7. CURING 20 DETIK\n8. KOMPOSIT A3 DENGAN TEKNIK INKREMENTAL\n9. CURING 20 DETIK \n10. COUNTURING \n11. FINISHING\n12.POLESHING	-	4122023043	Sahri Muhamad Risky	\N	\N	\N	\N	3420d0e2-9532-4e4e-b390-a24c88274678	1	\N
474d126d-59e3-4509-82ef-d2633a41429a	2024-05-27 13:42:46	Gigi 11	S: Gigi depan kanan berlubang\nO: Gigi 11 D4 (2,2)\nA: Diagnosis = Pulpa normal\nDD= Pulpitis reversibel\nP: Pro restorasi RK klas 4\nTahapan:\n1. Pembersihan gigi\n2. Pemilihan warna gigi\n3. Preparasi gigi\n4. Aplikasi etsa\n5. Aplikasi bonding\n6. Penambalan gigi\n7. Finishing dan polishing\n\ninstruksi :\n1. Jika tambalan lepas segera ke klinik terdekat\n2. Tidak memakan atau minum yang berwarna\n3. Tidak memakan makanan yang keras\n\nKontrol : h+2 minggu	-	4122023030	Faika Zahra Chairunnisa	\N	\N	\N	2024-05-27 13:43:02	ed967c41-3a29-49bb-ad8f-a62a8e62dfac	1	\N
8af137e2-0db7-43b1-b388-76f1bb5560af	2024-05-27 13:55:52	11 PN D4 1,3	- PEMERIKSAAN LENGKAP\n- PENGISISAN STATUS DAN ACC PASIEN\n- PREPARASI KELAS 5 DAN RESTORASI GIC\n- S: GIGI DEPAN ATAS KANAN BERLUBANG DAN TIDAK ADA RASA SAKIT\n- O: GIGI 11 PN D4 1,3\n- A: PULPA NORMAL /DD PULPITIS REVERSIBEL\n- P: 1. PEMBERSIHAN DAERAH SEKITAR \n2. ISOLASI DAERAH KERJA \n3. PREPARASI KELAS 3\n4. ETSA 10 DETIK\n5. BILAS ETSA\n6. APLIKASIKAN BONDING DENGAN MICROBRUSH\n7. CURING 20 DETIK\n8. GUNAKAN STRIP MATRIKS\n9. KOMPOSIT A2 \n10. CURING 20 DETIK \n11. COUNTURING \n12. FINISHING\n13.POLESHING	-	4122023043	Sahri Muhamad Risky	\N	\N	\N	\N	0bf6ec2c-3ec6-4e11-93ef-25fe8f7f4f30	1	\N
4de166f8-8d9f-4f50-b1df-e216ff5721bd	2024-05-27 14:32:29	12 PN D4 1,3	- PEMERIKSAAN LENGKAP\n- PENGISISAN STATUS DAN ACC PASIEN\n- PREPARASI KELAS 5 DAN RESTORASI GIC\n- S: GIGI DEPAN ATAS KANAN BERLUBANG DAN TIDAK ADA RASA SAKIT\n- O: GIGI 12 PN D4 1,3\n- A: PULPA NORMAL /DD PULPITIS REVERSIBEL\n- P: 1. PEMBERSIHAN DAERAH SEKITAR \n2. ISOLASI DAERAH KERJA \n3. PREPARASI KELAS 4\n4. ETSA 10 DETIK\n5. BILAS ETSA\n6. APLIKASIKAN BONDING DENGAN MICROBRUSH\n7. CURING 20 DETIK\n8. GUNAKAN STRIP MATRIKS\n9. KOMPOSIT A2\n10. CURING 20 DETIK \n11. COUNTURING \n12. FINISHING\n13.POLESHING	-	4122023043	Sahri Muhamad Risky	\N	\N	\N	\N	903407f6-2cd1-4d59-ae40-18706dd2d120	1	\N
5a65e61a-153a-4b00-a292-58bb7de37dd3	2024-05-27 16:47:22	36 pr D4 1,4	- PEMERIKSAAN LENGKAP\n- PENGISISAN STATUS DAN ACC PASIEN\n- PREPARASI KELAS 5 DAN RESTORASI GIC\n- S: GIGI BELAKANG BAWAH KANAN BERLUBANG DAN SENSITIF TERKENA RANGSANGAN\n- O: GIGI 46 PN D4 1,2\n- A:  PULPITIS REVERSIBEL/ DD PULPITIS IREVERSIBEL\n- P: 1. PEMBERSIHAN DAERAH SEKITAR \n2. ISOLASI DAERAH KERJA \n3. PREPARASI KELAS 2\n4.PEMASANGAN MATRIKS\n5. PENGGUNAAN RING  DENGAN FORCEPS\n6. ETSA 10 DETIK\n7. BILAS ETSA\n8. APLIKASIKAN BONDING DENGAN MICROBRUSH\n9. CURING 20 DETIK\n10. APLIKASIKAN KOMPOSIT FLOWABLE SELANJUTNYA KOMPOSIT A3\n11. CURING 20 DETIK \n12. COUNTURING \n13. FINISHING\n14.POLESHING	-	4122023043	Sahri Muhamad Risky	\N	\N	\N	\N	03777a93-2103-4d5a-b7a6-f3e10000fc9b	1	\N
aac4f84b-3129-4d85-96ba-3e96f7ec3e51	2024-05-27 17:42:12	gigi 12	s: gigi depan atas kanan pasien karies \no: gigi 12 \na: pulpa normal \n    DD : pulpitis reversible\np: restorasi komposit kelas III \n\n1. preparasi kelas III\n2. etsa \n3. bonding \n4. penambalan resin komposit kelas III\n5. polishing \n\nkontrol	penambalan : 8/5/24\nkontrol : 17/5/24	4122023027	Atika Rahma Minabari	\N	\N	\N	\N	367a2c46-9894-4ec3-9424-c419ae5a9700	1	\N
38e6c872-b957-4623-bb2e-cd9de8f7de9e	2024-05-27 18:44:13	Gigi 21	S : gigi depan atas kanan pasien patah \nO : gigi 21 \nA : pulpa normal\nP : restorasi komposit kelas IV \n1. preparasi \n2. etsa \n3. bonding \n4. penambalan resin komposit kelas IV \n\nKontrol	penambalan : 10/5/24\nkontrol : 24/5/24	4122023027	Atika Rahma Minabari	\N	\N	\N	\N	1783fc11-36d9-425e-9c3b-4348efdb46d0	1	\N
8bc4f096-fdbb-4dcb-ab73-61c172520bf3	2024-05-27 19:29:35	gigi 25	S: Gigi belakang kiri atas pasien karies \nO: gigi 25\nA: pulpa normal \nP:restorasi GIC kelas V\n\n1. isolasi daerah kerja \n2. preparasi \n3. dentin conditioner \n4 GIC \n\nkontrol	penambalan: 15/5/24\nkontrol : 21/524	4122023027	Atika Rahma Minabari	\N	\N	\N	\N	0ba60779-14ca-422a-85d2-3f3d0d534952	1	\N
804c8e97-3a2c-4e67-83f2-e10c72cc15e2	2024-05-27 21:17:50	gigi 47	S: gigi belakang kanan bagian bawah \nO: gigi 47\nA: pulpa normal \nP: restorasi komposit kelas II	penambalan : 16/5/24\nkontrol : 21/5/24	4122023027	Atika Rahma Minabari	\N	\N	\N	\N	c9cc4e55-33cb-4663-baf2-eb7c82cf3c8a	1	\N
7ead26e5-9568-4c22-a2d5-b9c5d74f819e	2024-05-27 23:31:15	Gigi 47 : karies kelas 2	S: gigi kanan bawah belakang sudah di tambal namun tambalannya terkisis\nO: gigi 47\nA: pulpitis reversible (DD: pulpitis irreversible)\nP: Penambalan resin komposit kelas 2\n1. Preparasi \n2. Etsa\n3. Bonding\n4. Penambalan 3M ESPE Filtek Z350 Xt A3\n5. Poles	-	4122023044	Sekar Decita Ananda Iswanti	\N	\N	\N	\N	024b339e-2e79-4b8a-880c-a6c39e529520	1	\N
80991ea6-88e1-452d-a1e0-66a034e77f36	2024-05-27 23:40:50	Gigi 23	S: gigi kiri atas depan berlubang dan tidak sakit\nO: gigi 23 \nA: pulpa normal (DD: pulpitis reversible)\nP: penambalan resin komposit kelas 3\n1. Preparasi\n2. Etsa\n3. Bonding\n4. Penambalan 3M ESPE Filtek Z350 Xt A2 \n5. Poles	-	4122023044	Sekar Decita Ananda Iswanti	\N	\N	\N	\N	fb5678cc-9351-4be4-bb2b-dbc13f92a02d	1	\N
edaa40a7-1cd4-4eef-b7f9-876e0052bf44	2024-05-28 00:57:23	Gigi 16	- Pemeriksaan Lengkap\n- Pengisian Status Pasien\n- ACC Pemeriksaan Lengkap\n\nS : Gigi atas kanan pasien abrasi dan pasien tidal merasakan sakit\nO : Gigi 16 PN\nA : Pulpa Normal\nP : Penambalan GIC Kelas 5\n1. Isolasi daerah kerja\n2. Poles\n3. Etsa\n4. Bonding\n5. GIC Kelas 5	✅	4122023026	Andi Adjani Salwa Putri	\N	\N	\N	\N	1ac28e25-0b37-436d-94fa-8603c4bd64f2	1	\N
57cb9799-89d1-497f-9036-b60ec86e78eb	2024-05-28 00:58:39	Gigi 16	Kontrol\n- Tidak ada perubahan warna\n- Tidak ada keluhan	✅	4122023026	Andi Adjani Salwa Putri	\N	\N	\N	\N	1ac28e25-0b37-436d-94fa-8603c4bd64f2	1	\N
23b3dd27-7654-4c1d-8286-04ab6137c95a	2024-05-28 01:07:30	Gigi 36	- Pemeriksaan Lengkap\n- Pengisian Status Pasien\n- ACC Pemeriksaan Lengkap\n\nS : Gigi bawah kiri pasien berlubang dan pasien tidak merasakan sakit\nO : Gigi 36 PN (D3, S2, S2)\nA : Pulpa Normal\nP : Penambalan RK Kelas 2\n1. Isolasi daerah kerja\n2. Preparasi RK kelas 2\n3. Etsa \n4. Bonding\n5. Poles	✅	4122023026	Andi Adjani Salwa Putri	\N	\N	\N	\N	2938249f-54c8-4b9f-a252-6d4fbcccd2ca	1	\N
52f04503-c5f6-45c6-bff2-1a7c77e6589c	2024-05-28 01:07:58	Gigi 36	Kontrol\n- Tidak ada perubahan warna\n- Tidak ada keluhan	✅	4122023026	Andi Adjani Salwa Putri	\N	\N	\N	\N	2938249f-54c8-4b9f-a252-6d4fbcccd2ca	1	\N
222cb1ad-05fc-40e5-9e79-b6c5db8ff85d	2024-05-28 01:18:40	Gigi 21	- Pemeriksaan Lengkap\n- Pengisian Status Pasien\n- ACC Pemeriksaan Lengkap\n\nS : Gigi atas kiri pasien terdapat gambaran kehitaman dibagian pinggir gigi dan adanya patas dibagian ujung gigi tana disertai rasa sakit\nO : Gigi 21 PN\nA : Pulpa Normal\nP : Penambalan RK Kelas 3\n1. Isolasi daerah kerja\n2. Preparasi RK kelas 3\n3. Etsa \n4. Bonding\n5. Penambalan RK Kelas 3\n6. Poles	✅	4122023026	Andi Adjani Salwa Putri	\N	\N	\N	\N	026ab7ae-a532-4014-a909-9c3111756fbe	1	\N
cd52eb91-0172-4640-96eb-0ad1b23b4999	2024-05-28 01:19:13	Gigi 21	Kontrol\n- Tidak ada perubahan warna\n- Tidak ada keluhan	✅	4122023026	Andi Adjani Salwa Putri	\N	\N	\N	\N	026ab7ae-a532-4014-a909-9c3111756fbe	1	\N
b4e9b885-013f-4485-b359-5b6e3a4c0964	2024-05-28 01:26:44	Gigi 21	- Pemeriksaan Lengkap\n- Pengisian Status Pasien\n- ACC Pemeriksaan Lengkap\n\nS : Gigi atas kiri pasien path dan ingin ditambal. Pasien tidak merasakan sakit\nO : Gigi 21 PN\nA : Pulpa Normal\nP : Penambalan RK Kelas 4\n1. Isolasi daerah kerja\n2. Preparasi RK kelas 4\n3. Etsa \n4. Bonding\n5. Penambalan RK Kelas 4\n6. Poles	✅	4122023026	Andi Adjani Salwa Putri	\N	\N	\N	\N	2b949371-6b4f-462e-9ab4-836fc1409ab6	1	\N
fd95d49a-41ce-4a63-8d3a-ab235624daf6	2024-05-28 01:27:10	Gigi 21	Kontrol\n- Tidak ada perubahan warna\n- Tidak ada keluhan	✅	4122023026	Andi Adjani Salwa Putri	\N	\N	\N	\N	2b949371-6b4f-462e-9ab4-836fc1409ab6	1	\N
593af2da-6c87-481f-8d5e-d830ae517397	2024-05-28 08:06:56	Gigi 11 Berlubang	S : Gigi seri atas kanan berlubang, tidak ada rasa sakit\nO : Gigi 11 PN DN (3,1)\nA : Pulpa Normal\nP : Penambalan GIC Kelas 5\n- Preparasi Kelas 5\n-  DentinConditioner \n- Penambalan GIC Kelas 5\n- Poles	-	4122023036	Karina Ivana Nariswari	\N	\N	\N	\N	de127d9f-d414-46de-a365-b754998c996e	1	\N
03acd775-ca64-49c5-988c-052ee06183b6	2024-05-28 08:03:10	Gigi 11 berlubang\nTindakan\nS : Gigi seri atas kanan berlubang, tidak ada rasa sakit \nO : PN D3 (2,1)\nA : Pulpa Normal\nP : Penambalan Resin Komposit Kelas 3 \n- Preparasi Kelas 3\n- Etsa\n- Bonding\n- Penambalan Resin Komposit Kelas 3\n-  Poles	S : Gigi seri atas kanan berlubang, tidak ada rasa sakit \nO : PN D3 (2,1)\nA : Pulpa Normal\nP : Penambalan Resin Komposit Kelas 3 \n- Preparasi Kelas 3\n- Etsa\n- Bonding\n- Penambalan Resin Komposit Kelas 3\n-  Poles	-	4122023036	Karina Ivana Nariswari	\N	\N	\N	2024-05-28 08:07:29	de127d9f-d414-46de-a365-b754998c996e	1	\N
3544593c-4f64-4646-b5e6-46d12cf1ead3	2024-05-28 08:21:34	Gigi 47	Kontrol :\n1. tambalan sudah dapat digunakan untuk makan\n2. tidak ada rasa sakit	-	4122023044	Sekar Decita Ananda Iswanti	\N	\N	\N	\N	e676ed53-2733-4938-9841-9e66a69c8c81	1	\N
0b999878-6755-4e92-a7de-52ff2f09bca3	2024-05-28 09:00:16	Gigi 47 D3 S1 S2	Pemeriksaan Lengkap\nPengisian status pasien\n\nS=Gigi geraham bawah kanan pasien berlubang dan tidak ada rasa sakit\nO=Gigi 47 PN (D3 S1 S2)\nA=Pulpa Normal\nP=Penambalan RK Klas 1\n\n1. Preparasi klas 1\n2. etsa\n3. bonding\n4. penambalan rk klas 1\n5. poles\n6. kontrol tambalan 1 minggu setelah perawatan	Gigi 47 tidak ada keluhan setelah perawatan	4122023042	Rayyen Alfian Juneanro	\N	\N	\N	\N	ee5c90c9-dd88-4563-aba8-ac93f7fbaec4	1	\N
2e9e2590-7201-418e-ad3d-018540158dc7	2024-05-28 09:11:53	Gigi 21 M Car (D3 S2 S2)	RK Klas 3\nPemeriksaan lengkap\nPengisian status pasien\n\nS=Gigi depan pasien berlubang tidak ada rasa sakit\nO=Gigi 21 PN (D3 S2 S2)\nA=Pulpa Normal\nP=Penambalan RK Klas 3\n\n1. Preparasi klas 3\n2. etsa\n3. bonding\n4. penambalan klas 3\n5. poles\n6. kontrol 1 minggu setelah perawatan\n\nRK Klas 4\n\nPemeriksaan lengkap\nPengisian status pasien\n\nS=Gigi depan pasien berlubang tidak ada rasa sakit\nO=Gigi 21 PN (D3 S2 S2)\nA=Pulpa Normal\nP=Penambalan RK Klas 4\n\n1. Preparasi klas 4\n2. etsa\n3. bonding\n4. penambalan klas 4\n5. poles\n6. kontrol 1 minggu setelah perawatan	Gigi 21 tidak ada keluhan setelah perawatan	4122023042	Rayyen Alfian Juneanro	\N	\N	\N	2024-05-28 09:13:50	00ed68a0-68cf-4911-a82c-b8763f37c7a3	1	\N
4cc36d7e-e2e0-4eae-9f5c-9d4ad8a6f14d	2024-05-28 09:25:41	Gigi 25 D3 S3 S2	Pemeriksaan lengkap\nPengisian status pasien\n\nS=Gigi belakang pasien berlubang sering nyangkut makanan\nO=Gigi 25 PN (D3 S3 S2)\nA=Pulpa Normal\nP=Penambalan GIC\n\n1. Dentin Conditioner\n2. Penambalan GIC\n3. Poles 1 hari setelah perawatan\n4. Kontrol GIC 1 Minggu setelah perawatan	Gigi 25 tidak ada keluhan setelah perawatan	4122023042	Rayyen Alfian Juneanro	\N	\N	\N	\N	fa8331d0-ba9e-449b-b627-becd081a1e18	1	\N
\.


--
-- TOC entry 3711 (class 0 OID 16450)
-- Dependencies: 219
-- Data for Name: emrkonservasis; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.emrkonservasis (id, noregister, noepisode, nomorrekammedik, tanggal, namapasien, pekerjaan, jeniskelamin, alamatpasien, nomortelpon, namaoperator, nim, sblmperawatanpemeriksaangigi_18_tv, sblmperawatanpemeriksaangigi_17_tv, sblmperawatanpemeriksaangigi_16_tv, sblmperawatanpemeriksaangigi_15_55_tv, sblmperawatanpemeriksaangigi_14_54_tv, sblmperawatanpemeriksaangigi_13_53_tv, sblmperawatanpemeriksaangigi_12_52_tv, sblmperawatanpemeriksaangigi_11_51_tv, sblmperawatanpemeriksaangigi_21_61_tv, sblmperawatanpemeriksaangigi_22_62_tv, sblmperawatanpemeriksaangigi_23_63_tv, sblmperawatanpemeriksaangigi_24_64_tv, sblmperawatanpemeriksaangigi_25_65_tv, sblmperawatanpemeriksaangigi_26_tv, sblmperawatanpemeriksaangigi_27_tv, sblmperawatanpemeriksaangigi_28_tv, sblmperawatanpemeriksaangigi_18_diagnosis, sblmperawatanpemeriksaangigi_17_diagnosis, sblmperawatanpemeriksaangigi_16_diagnosis, sblmperawatanpemeriksaangigi_15_55_diagnosis, sblmperawatanpemeriksaangigi_14_54_diagnosis, sblmperawatanpemeriksaangigi_13_53_diagnosis, sblmperawatanpemeriksaangigi_12_52_diagnosis, sblmperawatanpemeriksaangigi_11_51_diagnosis, sblmperawatanpemeriksaangigi_21_61_diagnosis, sblmperawatanpemeriksaangigi_22_62_diagnosis, sblmperawatanpemeriksaangigi_23_63_diagnosis, sblmperawatanpemeriksaangigi_24_64_diagnosis, sblmperawatanpemeriksaangigi_25_65_diagnosis, sblmperawatanpemeriksaangigi_26_diagnosis, sblmperawatanpemeriksaangigi_27_diagnosis, sblmperawatanpemeriksaangigi_28_diagnosis, sblmperawatanpemeriksaangigi_18_rencanaperawatan, sblmperawatanpemeriksaangigi_17_rencanaperawatan, sblmperawatanpemeriksaangigi_16_rencanaperawatan, sblmperawatanpemeriksaangigi_15_55_rencanaperawatan, sblmperawatanpemeriksaangigi_14_54_rencanaperawatan, sblmperawatanpemeriksaangigi_13_53_rencanaperawatan, sblmperawatanpemeriksaangigi_12_52_rencanaperawatan, sblmperawatanpemeriksaangigi_11_51_rencanaperawatan, sblmperawatanpemeriksaangigi_21_61_rencanaperawatan, sblmperawatanpemeriksaangigi_22_62_rencanaperawatan, sblmperawatanpemeriksaangigi_23_63_rencanaperawatan, sblmperawatanpemeriksaangigi_24_64_rencanaperawatan, sblmperawatanpemeriksaangigi_25_65_rencanaperawatan, sblmperawatanpemeriksaangigi_26_rencanaperawatan, sblmperawatanpemeriksaangigi_27_rencanaperawatan, sblmperawatanpemeriksaangigi_28_rencanaperawatan, sblmperawatanpemeriksaangigi_41_81_tv, sblmperawatanpemeriksaangigi_42_82_tv, sblmperawatanpemeriksaangigi_43_83_tv, sblmperawatanpemeriksaangigi_44_84_tv, sblmperawatanpemeriksaangigi_45_85_tv, sblmperawatanpemeriksaangigi_46_tv, sblmperawatanpemeriksaangigi_47_tv, sblmperawatanpemeriksaangigi_48_tv, sblmperawatanpemeriksaangigi_38_tv, sblmperawatanpemeriksaangigi_37_tv, sblmperawatanpemeriksaangigi_36_tv, sblmperawatanpemeriksaangigi_35_75_tv, sblmperawatanpemeriksaangigi_34_74_tv, sblmperawatanpemeriksaangigi_33_73_tv, sblmperawatanpemeriksaangigi_32_72_tv, sblmperawatanpemeriksaangigi_31_71_tv, sblmperawatanpemeriksaangigi_41_81_diagnosis, sblmperawatanpemeriksaangigi_42_82_diagnosis, sblmperawatanpemeriksaangigi_43_83_diagnosis, sblmperawatanpemeriksaangigi_44_84_diagnosis, sblmperawatanpemeriksaangigi_45_85_diagnosis, sblmperawatanpemeriksaangigi_46_diagnosis, sblmperawatanpemeriksaangigi_47_diagnosis, sblmperawatanpemeriksaangigi_48_diagnosis, sblmperawatanpemeriksaangigi_38_diagnosis, sblmperawatanpemeriksaangigi_37_diagnosis, sblmperawatanpemeriksaangigi_36_diagnosis, sblmperawatanpemeriksaangigi_35_75_diagnosis, sblmperawatanpemeriksaangigi_34_74_diagnosis, sblmperawatanpemeriksaangigi_33_73_diagnosis, sblmperawatanpemeriksaangigi_32_72_diagnosis, sblmperawatanpemeriksaangigi_31_71_diagnosis, sblmperawatanpemeriksaangigi_41_81_rencanaperawatan, sblmperawatanpemeriksaangigi_42_82_rencanaperawatan, sblmperawatanpemeriksaangigi_43_83_rencanaperawatan, sblmperawatanpemeriksaangigi_44_84_rencanaperawatan, sblmperawatanpemeriksaangigi_45_85_rencanaperawatan, sblmperawatanpemeriksaangigi_46_rencanaperawatan, sblmperawatanpemeriksaangigi_47_rencanaperawatan, sblmperawatanpemeriksaangigi_48_rencanaperawatan, sblmperawatanpemeriksaangigi_38_rencanaperawatan, sblmperawatanpemeriksaangigi_37_rencanaperawatan, sblmperawatanpemeriksaangigi_36_rencanaperawatan, sblmperawatanpemeriksaangigi_35_75_rencanaperawatan, sblmperawatanpemeriksaangigi_34_74_rencanaperawatan, sblmperawatanpemeriksaangigi_33_73_rencanaperawatan, sblmperawatanpemeriksaangigi_32_72_rencanaperawatan, sblmperawatanpemeriksaangigi_31_71_rencanaperawatan, ssdhperawatanpemeriksaangigi_18_tv, ssdhperawatanpemeriksaangigi_17_tv, ssdhperawatanpemeriksaangigi_16_tv, ssdhperawatanpemeriksaangigi_15_55_tv, ssdhperawatanpemeriksaangigi_14_54_tv, ssdhperawatanpemeriksaangigi_13_53_tv, ssdhperawatanpemeriksaangigi_12_52_tv, ssdhperawatanpemeriksaangigi_11_51_tv, ssdhperawatanpemeriksaangigi_21_61_tv, ssdhperawatanpemeriksaangigi_22_62_tv, ssdhperawatanpemeriksaangigi_23_63_tv, ssdhperawatanpemeriksaangigi_24_64_tv, ssdhperawatanpemeriksaangigi_25_65_tv, ssdhperawatanpemeriksaangigi_26_tv, ssdhperawatanpemeriksaangigi_27_tv, ssdhperawatanpemeriksaangigi_28_tv, ssdhperawatanpemeriksaangigi_18_diagnosis, ssdhperawatanpemeriksaangigi_17_diagnosis, ssdhperawatanpemeriksaangigi_16_diagnosis, ssdhperawatanpemeriksaangigi_15_55_diagnosis, ssdhperawatanpemeriksaangigi_14_54_diagnosis, ssdhperawatanpemeriksaangigi_13_53_diagnosis, ssdhperawatanpemeriksaangigi_12_52_diagnosis, ssdhperawatanpemeriksaangigi_11_51_diagnosis, ssdhperawatanpemeriksaangigi_21_61_diagnosis, ssdhperawatanpemeriksaangigi_22_62_diagnosis, ssdhperawatanpemeriksaangigi_23_63_diagnosis, ssdhperawatanpemeriksaangigi_24_64_diagnosis, ssdhperawatanpemeriksaangigi_25_65_diagnosis, ssdhperawatanpemeriksaangigi_26_diagnosis, ssdhperawatanpemeriksaangigi_27_diagnosis, ssdhperawatanpemeriksaangigi_28_diagnosis, ssdhperawatanpemeriksaangigi_18_rencanaperawatan, ssdhperawatanpemeriksaangigi_17_rencanaperawatan, ssdhperawatanpemeriksaangigi_16_rencanaperawatan, ssdhperawatanpemeriksaangigi_15_55_rencanaperawatan, ssdhperawatanpemeriksaangigi_14_54_rencanaperawatan, ssdhperawatanpemeriksaangigi_13_53_rencanaperawatan, ssdhperawatanpemeriksaangigi_12_52_rencanaperawatan, ssdhperawatanpemeriksaangigi_11_51_rencanaperawatan, ssdhperawatanpemeriksaangigi_21_61_rencanaperawatan, ssdhperawatanpemeriksaangigi_22_62_rencanaperawatan, ssdhperawatanpemeriksaangigi_23_63_rencanaperawatan, ssdhperawatanpemeriksaangigi_24_64_rencanaperawatan, ssdhperawatanpemeriksaangigi_25_65_rencanaperawatan, ssdhperawatanpemeriksaangigi_26_rencanaperawatan, ssdhperawatanpemeriksaangigi_27_rencanaperawatan, ssdhperawatanpemeriksaangigi_28_rencanaperawatan, ssdhperawatanpemeriksaangigi_41_81_tv, ssdhperawatanpemeriksaangigi_42_82_tv, ssdhperawatanpemeriksaangigi_43_83_tv, ssdhperawatanpemeriksaangigi_44_84_tv, ssdhperawatanpemeriksaangigi_45_85_tv, ssdhperawatanpemeriksaangigi_46_tv, ssdhperawatanpemeriksaangigi_47_tv, ssdhperawatanpemeriksaangigi_48_tv, ssdhperawatanpemeriksaangigi_38_tv, ssdhperawatanpemeriksaangigi_37_tv, ssdhperawatanpemeriksaangigi_36_tv, ssdhperawatanpemeriksaangigi_35_75_tv, ssdhperawatanpemeriksaangigi_34_74_tv, ssdhperawatanpemeriksaangigi_33_73_tv, ssdhperawatanpemeriksaangigi_32_72_tv, ssdhperawatanpemeriksaangigi_31_71_tv, ssdhperawatanpemeriksaangigi_41_81_diagnosis, ssdhperawatanpemeriksaangigi_42_82_diagnosis, ssdhperawatanpemeriksaangigi_43_83_diagnosis, ssdhperawatanpemeriksaangigi_44_84_diagnosis, ssdhperawatanpemeriksaangigi_45_85_diagnosis, ssdhperawatanpemeriksaangigi_46_diagnosis, ssdhperawatanpemeriksaangigi_47_diagnosis, ssdhperawatanpemeriksaangigi_48_diagnosis, ssdhperawatanpemeriksaangigi_38_diagnosis, ssdhperawatanpemeriksaangigi_37_diagnosis, ssdhperawatanpemeriksaangigi_36_diagnosis, ssdhperawatanpemeriksaangigi_35_75_diagnosis, ssdhperawatanpemeriksaangigi_34_74_diagnosis, ssdhperawatanpemeriksaangigi_33_73_diagnosis, ssdhperawatanpemeriksaangigi_32_72_diagnosis, ssdhperawatanpemeriksaangigi_31_71_diagnosis, ssdhperawatanpemeriksaangigi_41_81_rencanaperawatan, ssdhperawatanpemeriksaangigi_42_82_rencanaperawatan, ssdhperawatanpemeriksaangigi_43_83_rencanaperawatan, ssdhperawatanpemeriksaangigi_44_84_rencanaperawatan, ssdhperawatanpemeriksaangigi_45_85_rencanaperawatan, ssdhperawatanpemeriksaangigi_46_rencanaperawatan, ssdhperawatanpemeriksaangigi_47_rencanaperawatan, ssdhperawatanpemeriksaangigi_48_rencanaperawatan, ssdhperawatanpemeriksaangigi_38_rencanaperawatan, ssdhperawatanpemeriksaangigi_37_rencanaperawatan, ssdhperawatanpemeriksaangigi_36_rencanaperawatan, ssdhperawatanpemeriksaangigi_35_75_rencanaperawatan, ssdhperawatanpemeriksaangigi_34_74_rencanaperawatan, ssdhperawatanpemeriksaangigi_33_73_rencanaperawatan, ssdhperawatanpemeriksaangigi_32_72_rencanaperawatan, ssdhperawatanpemeriksaangigi_31_71_rencanaperawatan, sblmperawatanfaktorrisikokaries_sikap, sblmperawatanfaktorrisikokaries_status, sblmperawatanfaktorrisikokaries_saliva_tanpastimulasi_hidrasi, sblmperawatanfaktorrisikokaries_saliva_tanpastimulasi_viskosita, "sblmperawatanfaktorrisikokaries_saliva_tanpastimulasi_pH", sblmperawatanfaktorrisikokaries_saliva_denganstimulasi_hidrasi, sblmperawatanfaktorrisikokaries_saliva_denganstimulasi_kecepata, sblmperawatanfaktorrisikokaries_saliva_denganstimulasi_kapasita, "sblmperawatanfaktorrisikokaries_saliva_denganstimulasi_pH", "sblmperawatanfaktorrisikokaries_plak_pH", sblmperawatanfaktorrisikokaries_plak_aktivitas, sblmperawatanfaktorrisikokaries_fluor_pastagigi, sblmperawatanfaktorrisikokaries_diet_gula, sblmperawatanfaktorrisikokaries_faktormodifikasi_obatpeningkata, sblmperawatanfaktorrisikokaries_faktormodifikasi_penyakitpenyeb, sblmperawatanfaktorrisikokaries_faktormodifikasi_protesa, sblmperawatanfaktorrisikokaries_faktormodifikasi_kariesaktif, sblmperawatanfaktorrisikokaries_faktormodifikasi_sikap, sblmperawatanfaktorrisikokaries_faktormodifikasi_keterangan, sblmperawatanfaktorrisikokaries_penilaianakhir_saliva, sblmperawatanfaktorrisikokaries_penilaianakhir_plak, sblmperawatanfaktorrisikokaries_penilaianakhir_diet, sblmperawatanfaktorrisikokaries_penilaianakhir_fluor, sblmperawatanfaktorrisikokaries_penilaianakhir_faktormodifikasi, ssdhperawatanfaktorrisikokaries_sikap, ssdhperawatanfaktorrisikokaries_status, ssdhperawatanfaktorrisikokaries_saliva_tanpastimulasi_hidrasi, ssdhperawatanfaktorrisikokaries_saliva_tanpastimulasi_viskosita, "ssdhperawatanfaktorrisikokaries_saliva_tanpastimulasi_pH", ssdhperawatanfaktorrisikokaries_saliva_denganstimulasi_hidrasi, ssdhperawatanfaktorrisikokaries_saliva_denganstimulasi_kecepata, ssdhperawatanfaktorrisikokaries_saliva_denganstimulasi_kapasita, "ssdhperawatanfaktorrisikokaries_saliva_denganstimulasi_pH", "ssdhperawatanfaktorrisikokaries_plak_pH", ssdhperawatanfaktorrisikokaries_plak_aktivitas, ssdhperawatanfaktorrisikokaries_fluor_pastagigi, ssdhperawatanfaktorrisikokaries_diet_gula, ssdhperawatanfaktorrisikokaries_faktormodifikasi_obatpeningkata, ssdhperawatanfaktorrisikokaries_faktormodifikasi_penyakitpenyeb, ssdhperawatanfaktorrisikokaries_faktormodifikasi_protesa, ssdhperawatanfaktorrisikokaries_faktormodifikasi_kariesaktif, ssdhperawatanfaktorrisikokaries_faktormodifikasi_sikap, ssdhperawatanfaktorrisikokaries_faktormodifikasi_keterangan, ssdhperawatanfaktorrisikokaries_penilaianakhir_saliva, ssdhperawatanfaktorrisikokaries_penilaianakhir_plak, ssdhperawatanfaktorrisikokaries_penilaianakhir_diet, ssdhperawatanfaktorrisikokaries_penilaianakhir_fluor, ssdhperawatanfaktorrisikokaries_penilaianakhir_faktormodifikasi, sikatgigi2xsehari, sikatgigi3xsehari, flossingsetiaphari, sikatinterdental, agenantibakteri_obatkumur, guladancemilandiantarawaktumakanutama, minumanasamtinggi, minumanberkafein, meningkatkanasupanair, obatkumurbakingsoda, konsumsimakananminumanberbahandasarsusu, permenkaretxylitolccpacp, pastagigi, kumursetiaphari, kumursetiapminggu, gelsetiaphari, gelsetiapminggu, perlu, tidakperlu, evaluasi_sikatgigi2xsehari, evaluasi_sikatgigi3xsehari, evaluasi_flossingsetiaphari, evaluasi_sikatinterdental, evaluasi_agenantibakteri_obatkumur, evaluasi_guladancemilandiantarawaktumakanutama, evaluasi_minumanasamtinggi, evaluasi_minumanberkafein, evaluasi_meningkatkanasupanair, evaluasi_obatkumurbakingsoda, evaluasi_konsumsimakananminumanberbahandasarsusu, evaluasi_permenkaretxylitolccpacp, evaluasi_pastagigi, evaluasi_kumursetiaphari, evaluasi_kumursetiapminggu, evaluasi_gelsetiaphari, evaluasi_gelsetiapminggu, evaluasi_perlu, evaluasi_tidakperlu, created_at, updated_at, uploadrestorasibefore, uploadrestorasiafter, sblmperawatanfaktorrisikokaries_fluor_airminum, sblmperawatanfaktorrisikokaries_fluor_topikal, sblmperawatanfaktorrisikokaries_diet_asam, ssdhperawatanfaktorrisikokaries_fluor_airminum, ssdhperawatanfaktorrisikokaries_fluor_topikal, ssdhperawatanfaktorrisikokaries_diet_asam, status_emr, status_penilaian) FROM stdin;
8a9c67d2-30e7-4354-b1af-2f3c51c712ee	RJJP080524-0580	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023035	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7b41257b-256f-4ec0-bfbd-235ba6dede07	RJJP060324-0455	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023042	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
c3687544-8223-4549-b59f-a0f7f19c7c14	RJJP080324-0342	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023044	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2dd84b16-6f43-4266-ba27-2b3dae65d61d	RJJP060324-0364	OP073193-060324-0013	07-31-93	2024-03-06 10:37:51	DINDA KANIA LARASATI, NN	MAHASISWA	F	BLOK R GG II / 63	08567818032	Qanita Regina Maharani	4122023041	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 09:16:23	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/f7853e4e-093b-448c-a0a0-d83f443ad12f.heic	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
1107fa0d-6be3-4dfa-ae05-b404ba0af3c2	RJJP080324-0342	OP073380-080324-0071	07-33-80	2024-03-08 09:39:22	AYASMINE VENEZIA ACHMAD, NN	PELAJAR	F	JL SWASEMBADA BARAT VIII NO 29	087870366379	Jihan Ar Rohim	4122023035	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 08:38:48	\N	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/f6a4df6a-b791-4dd4-a086-ba339d7ba14e.jpg	\N	\N	\N	\N	\N	\N	WRITE	\N
b76230ab-79a6-4829-8d34-86fd808c959f	RJJP080324-0356	OP073505-080324-0085	07-35-05	2024-03-08 09:50:21	AULIA MAULIDA FITRIANI. NN	MAHASISWA	F	JL NURUL HUDA I NO 2\r\n002/015	08990743556	Jihan Ar Rohim	4122023035	\N	+	+	\N	\N	\N	\N	+	+	\N	\N	\N	\N	+	\N	\N	\N	PN D3 (2,1)	PN D3 (2,1)	\N	\N	\N	\N	PN D3 (2,1)	PN D3 (2,1)	\N	\N	\N	\N	PN D4 (3,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	Restorasi kelas 3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	+	+	\N	\N	+	+	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	PN D3 (3,1)	PN D3 (1,1)	\N	\N	PN D2 (1,1)	PR D5 (1,3)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 08:51:40	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/5e3cb7fe-f837-4b54-89fc-14f6eba6475d.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/1040a411-1173-49f7-9c2b-562236aa4ef8.jpg	\N	\N	\N	\N	\N	\N	WRITE	\N
91e6c73d-74b3-429d-9a71-d030a56159c4	RJJP130324-0333	OP073380-130324-0329	07-33-80	2024-03-13 10:45:37	AYASMINE VENEZIA ACHMAD, NN	PELAJAR	F	JL SWASEMBADA BARAT VIII NO 29	087870366379	Jihan Ar Rohim	4122023035	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	PN D3 (1,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	PN D2 (1,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	PN D3 (1,1)	\N	\N	\N	\N	\N	PN D4 (1,2)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 08:12:31	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/1b8ba0fd-dec4-4a90-ab27-250ba65b8563.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/8bad66f4-8e6e-435c-91a9-a5b59eec827b.jpg	\N	\N	\N	\N	\N	\N	WRITE	\N
8d62211f-32d6-46d9-8846-ce0c87036157	RJJP070324-0227	OP072314-070324-0039	07-23-14	2024-03-07 08:39:05	RITA AGUSTIN. NY	I R T	F	PERUM BUMI PERMATA ESTATE	08983200776	Jihan Ar Rohim	4122023035	\N	+	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	PN D3 (2,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	PN D2 (1,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	\N	\N	\N	PN D5 (1,3)	O COF	\N	\N	\N	\N	PN D3 (2,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Restorasi RK kelas 2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 09:17:37	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/dbc583a4-7ba9-488d-9ab1-b8519fe6db05.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/3c6baa28-7485-4bfe-99ac-03bca9fdce9f.jpg	\N	\N	\N	\N	\N	\N	WRITE	\N
7dda1b96-197d-466b-813c-451b64c6a6ef	RJJP010324-0214	OP073601-010324-0407	07-36-01	2024-03-01 09:03:14	AMALIA SALSABILA, NN	MAHASISWA	F	JL. HAJI HASBI 2 NO.17	081383916045	Qanita Regina Maharani	4122023041	+	\N	+	\N	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	\N	PN D3 (1,1)	\N	PN D4 (2,2)	\N	\N	\N	PN D3 (1,1)	\N	PN D4 (1,1)	PN D4 (1,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 09:48:09	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/da21717a-e3be-4119-a4e6-b22778eac5bf.jpeg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/000a4ab0-d550-45aa-b744-0c401ed603cf.jpeg	\N	\N	\N	\N	\N	\N	WRITE	\N
9d222a21-63ff-485a-9b31-c4b7490a4894	RJJP050324-0481	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023035	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
f198d1d5-06df-4c60-9439-1b4f6969f304	RJJP130524-0450	OP052564-130524-0236	05-25-64	2024-05-13 11:33:50	RAYYEN ALFRIAN JUNEANDRO,TN	MAHASISWA	M	JL TITIHAN 6 BLOK HF 13 NO 14	085747324531	Atika Rahma Minabari	4122023027	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	o car (d3,s1,s1)	\N	v car d3,s3,s1	\N	\N	v car d3,s3,s1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	resin komposit kelas 1	\N	resin komposit kelas 1	\N	\N	resin komposit kelas 5	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 11:24:06	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
00fe3891-61f9-4b7d-aea7-81f1fe0c3cd8	RJJP040324-0244	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023035	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
fb19fecd-0968-4277-81a8-98e830e075f9	RJJP010324-0136	OP067212-010324-0365	06-72-12	2024-03-01 08:21:13	TANIA RESTIANA, NN	MAHASISWA	F	JL MANGGAN BESAR XIII RT.005/003	089513989606	Jihan Ar Rohim	4122023035	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Fraktur insisal	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Restorasi kelas 4	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Miss	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 09:38:22	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/661b0a44-8e18-46c9-958b-9fe9de92e641.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/18aea5b6-378e-4eb6-9392-a183fb181534.jpg	\N	\N	\N	\N	\N	\N	WRITE	\N
08a54fdf-be1c-415f-b961-78faf3e7c33f	RJJP260324-0243	OP074808-260324-0434	07-48-08	2024-03-26 08:58:22	ANGGI PRASETYO, TN	SWASTA	M	JL. BATU	085777037071	Jihan Ar Rohim	4122023035	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	PN D3 (1,2)	PN D3 (2,1)	PN D3 (1,1)	\N	\N	\N	\N	PN D3 (2,1)	PN D3 (2,1)	\N	PN D3 (3,1)	\N	\N	\N	PN D3 (1,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	PN D2 (1,1)	Rex	PN D3 (1,1)	PN D3 (1,2)	PN D2 (1,1)	PN D6 (1,1)	PN D3 (1,1)	PN D3 (1,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 09:52:31	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/1753dfbe-1bdb-4124-9aa2-473440497163.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/6704d121-016d-44ee-b631-c34454aa6db5.jpg	\N	\N	\N	\N	\N	\N	WRITE	\N
7fb41011-dcee-4585-8f2b-f7ff2a2123f7	RJJP260324-0386	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023038	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
f22d5e89-4426-46c1-9c81-76a3055836b0	RJJP070324-0325	OP073105-070324-0116	07-31-05	2024-03-07 09:21:14	RADIUS DELANO TRI SATYA, TN	KARYAWAN/TI	M	PONDOK KOPI BLOK U.I NO 10 RT 007/006	087889653567	Laras Fajri Nanda Widiiswa	4122023038	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	+	+	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	PN D3(1,2)	PR D4(1,2)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	composite	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 10:17:53	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/d1ef71a2-e629-4ec2-929e-6469dfe0b013.heic	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/bb4f8f09-8c3b-45a6-8ad5-22a239687876.heic	\N	\N	\N	\N	\N	\N	WRITE	\N
83918a99-6994-4705-8b66-a8a56b10583f	RJJP210324-0186	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023035	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4ecf16ee-528f-408d-9c33-de5b7057f143	RJJP200324-0424	OP074808-200324-0090	07-48-08	2024-03-20 12:30:14	ANGGI PRASETYO, TN	SWASTA	M	JL. BATU	085777037071	Laras Fajri Nanda Widiiswa	4122023038	+	\N	+	\N	+	\N	+	\N	+	\N	\N	+	\N	\N	+	+	PN D3 (1,2)	\N	PN D3 (1,2)	\N	PN D3 (3,1)	\N	PN D3 (2,2)	\N	PN D3 (2,2)	\N	\N	PN D3 (3,1)	\N	MISS	PN D3(1,2)	PN D3 (1,2)	\N	\N	\N	\N	Composite	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	+	+	+	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	RRX	PN D3 (1,2)	PN D3 (1,2)	PN D3(1,2)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 10:50:43	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
3420d0e2-9532-4e4e-b390-a24c88274678	RJJP080524-0672	OP073195-080524-0092	07-31-95	2024-05-08 15:56:01	FAIKA ZAHRA CHAIRUNISA, NN	MAHASISWA	F	JL SPG VII	081383845586	Sahri Muhamad Risky	4122023043	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	PN D4 1,1	PN D3 1,1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	PN D4 1,2	PN D4 1,1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	PN D4 1,2	PN D4 1,2	\N	\N	PN D4 1,2	PN D4 1,2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 13:32:51	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/861b1cfa-77d8-44b2-911b-0095b57984b3.jpeg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/c0196de1-77d3-43d3-b6be-5f07181086fc.jpeg	\N	\N	\N	\N	\N	\N	WRITE	\N
d46c2481-daa9-4986-a085-ceeaa3885134	RJJP040324-0183	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023041	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 21:47:50	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/835c1c2a-0354-401e-9768-1273d76c6302.jpeg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/0def5923-b68b-4315-b218-447af61a2baa.jpeg	\N	\N	\N	\N	\N	\N	WRITE	\N
ad454423-6988-4fdc-83cf-a6a303e5378c	RJJP180324-0240	OP074808-150324-0254	07-48-08	2024-03-18 08:44:13	ANGGI PRASETYO, TN	SWASTA	M	JL. BATU	085777037071	Laras Fajri Nanda Widiiswa	4122023038	+	\N	+	\N	+	\N	\N	\N	+	\N	\N	+	\N	\N	\N	\N	PN D3(1,2)	\N	PN D3 (1,2)	\N	PN D3 (3,1)	\N	\N	\N	PN D3 (2,2)	\N	\N	PN D3 (3,1)	\N	missing	PN D3 (1,2)	\N	\N	\N	\N	\N	Composite	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	+	+	+	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	RRX	PN D3 (1,2)	PN D3 (1,2)	PN D3 (1,2)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 10:42:51	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/4ec4962f-919b-4aa1-8bc7-a5db27fa199d.heic	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/54482604-eaaa-4ce0-8bee-f5b43e9e8fcd.jpeg	\N	\N	\N	\N	\N	\N	WRITE	\N
00fd1210-de37-4b52-871b-a0d1ab771c2b	RJJP130324-0566	OP071328-130324-0403	07-13-28	2024-03-13 14:00:28	MARLINA BINTI MARTO ,NY	KARYAWAN/TI	F	JL SALEMBA TENGAH	083874693982	Laras Fajri Nanda Widiiswa	4122023038	\N	\N	\N	\N	\N	\N	+	+	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	PR D4(2,1)	PR D4(2,2)	\N	\N	\N	\N	\N	RRX	\N	\N	\N	\N	\N	\N	\N	\N	composite	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	\N	\N	MISS	\N	\N	\N	\N	\N	MISS	PN D3(1,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 11:00:37	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/cb758d48-ac7b-4cdc-9848-db8fb8a693cf.heic	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/e94411bd-ded3-4471-a845-044ba1fd23c9.heic	\N	\N	\N	\N	\N	\N	WRITE	\N
0215cb9d-97f5-48b6-9532-20b639e11955	RJJP080324-0339	OP073193-080324-0068	07-31-93	2024-03-08 09:37:15	DINDA KANIA LARASATI, NN	MAHASISWA	F	BLOK R GG II / 63	08567818032	Sekar Decita Ananda Iswanti	4122023044	\N	V	V	\N	\N	\N	\N	V	\N	\N	\N	V	V	V	V	\N	\N	PR (D4,1,2)	PR (D4,1,2,)	\N	\N	\N	\N	Fraktur insisal	\N	\N	\N	PN (D3,1,1)	PN (D3,1,1)	PR (D4,1,2,)	PR (D4,1,2)	\N	\N	\N	\N	\N	\N	\N	\N	Penambalan kelas 4	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	V	V	V	V	V	\N	V	V	\N	V	\N	\N	\N	\N	\N	\N	PN (D3,1,1)	PN (D3,1,1)	PN (D3,1,1)	PN (D3,1,1)	PR (D4,1,2)	\N	PR (D5,1,1)	PR (D4,1,1)	\N	PR (D4,1,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 10:30:59	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/8b138a15-d18c-400e-b535-e0b846378dbb.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/c1f6cf33-52cb-4a6a-814b-a8d059e46aa1.jpg	\N	\N	\N	\N	\N	\N	WRITE	\N
7b61ce0e-7924-47b2-a6fc-de39f781570a	RJJP130324-0366	OP073193-130324-0214	07-31-93	2024-03-13 11:16:18	DINDA KANIA LARASATI, NN	MAHASISWA	F	BLOK R GG II / 63	08567818032	Sekar Decita Ananda Iswanti	4122023044	\N	V	V	\N	\N	\N	\N	V	\N	\N	\N	V	V	V	V	\N	\N	PR (D4,1,2)	PR (D4,1,2,)	\N	\N	\N	\N	Fraktur insisal	\N	\N	\N	PN (D3,1,1)	PN (D3,1,1)	PR (D4,1,2,)	PR (D4,1,2)	\N	\N	\N	\N	\N	\N	\N	\N	Penambalan kelas 4	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	V	V	V	V	V	\N	V	V	\N	V	\N	\N	\N	\N	\N	\N	PN (D3,1,1)	PN (D3,1,1)	PN (D3,1,1)	PN (D3,1,1)	PR (D4,1,2)	\N	PR (D5,1,1)	PR (D4,1,1)	\N	PR (D4,1,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 10:26:47	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/e9d1ad65-c39e-4a1c-98d3-7980c8a5a4f6.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/642847b4-eac7-49fb-9dc7-8f26fff0a5b9.jpg	\N	\N	\N	\N	\N	\N	WRITE	\N
f617ab22-6326-4485-9a54-7763b1e2f14b	RJJP200324-0392	OP073617-200324-0133	07-36-17	2024-03-20 11:43:51	MUNANIK, NY	I R T	F	KP BULU RT. 4 RW. 10	087874549205	Faika Zahra Chairunnisa	4122023030	\N	+	\N	+	\N	\N	\N	\N	\N	+	\N	+	\N	\N	+	+	\N	PN D4 (3,2)	mis	Crown	\N	mis	\N	\N	\N	PN D4 (2,2)	\N	PN D4 (2,2)	mis	mis	O Cof	PN D3 (1,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	-	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	rrx	mis	mis	mis	PN D5 (2,4)	mis	mis	mis	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 13:43:39	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
a375ec7a-17d1-46b2-a17d-eb732c878be1	RJJP250324-0291	OP074808-250324-0073	07-48-08	2024-03-25 09:38:01	ANGGI PRASETYO, TN	SWASTA	M	JL. BATU	085777037071	Qanita Regina Maharani	4122023041	+	\N	+	\N	\N	\N	\N	\N	+	\N	+	+	\N	\N	+	\N	PN D3 (1,2)	\N	PN D3 (1,2)	\N	\N	\N	\N	\N	D3 PN D3 (2,2)	\N	PN D3 (3,1)	PN D3 (3,1)	\N	mis	PN D3 (1,2)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	restorasi gic kelas V	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	+	+	+	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	radix	PN D3	PN D3 (1,2)	PN D3 (1,2)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 12:45:56	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/a08e33bb-9ac6-4cdd-8796-711e3347728f.jpeg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/12ffcb1b-bb64-4ba5-b800-e84a3a81e4f8.jpeg	\N	\N	\N	\N	\N	\N	WRITE	\N
2afe0215-6bdc-44fe-b3ab-0cf034808c26	RJJP050324-0098	OP073380-050324-0203	07-33-80	2024-03-05 07:55:06	AYASMINE VENEZIA ACHMAD, NN	PELAJAR	F	JL SWASEMBADA BARAT VIII NO 29	087870366379	Sekar Decita Ananda Iswanti	4122023044	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Pulpitis	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Tumpat Komposit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-28 12:32:36	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/295e48f9-90ae-46fd-ad37-610603ca3d80.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/7735affe-8fac-4f71-b0f4-0b43ce2b0326.jpg	\N	\N	\N	\N	\N	\N	WRITE	\N
a51f1eb8-dc49-4c16-b9ce-badffc63b499	RJJP010324-0225	OP073108-010324-0418	07-31-08	2024-03-01 09:07:00	SAHRI MUHAMAD RIZKY, TN	KARYAWAN/TI	M	JL AK GANI	081281122718	Faika Zahra Chairunnisa	4122023030	\N	+	\N	\N	\N	\N	\N	\N	\N	\N	\N	+	\N	\N	+	\N	\N	PN D4 (1,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	MO Cof	\N	\N	PN D3 (1,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	+	+	+	\N	\N	+	+	\N	\N	\N	\N	\N	\N	\N	\N	\N	PN D3 (1,1)	PN D3 (1,2)	O Cof	\N	\N	Pre, PN D3 (1,1)	PN D5 (1,2)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Pro restorasi klas 1 RK	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 12:21:34	\N	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/27b39ee7-848d-43c2-9c94-46dfeb36733c.HEIC	\N	\N	\N	\N	\N	\N	WRITE	\N
6dfb7ea4-3f41-4c82-b66b-9832d8ea20af	RJJP200324-0451	OP066705-200324-0117	06-67-05	2024-03-20 13:07:00	ONG KU AN, TN	KARYAWAN/TI	M	JL. GG TOYIB NO. 1A	08161155930	Faika Zahra Chairunnisa	4122023030	\N	\N	+	+	\N	\N	\N	\N	+	+	\N	-	+	\N	+	+	\N	\N	Amf	PN D4 (3,2)	\N	\N	\N	\N	Cof	Crown	\N	rrx	PN D2 (2,2)	\N	O Cof	PN D4 (1,2)	\N	\N	\N	Pro restorasi klas V	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	+	\N	-	+	+	+	\N	+	+	+	\N	+	\N	\N	\N	\N	PN D4 (1,1)	\N	rrx	O Amf	PN D3 (1,1)	O Cof	miss	d Amf	Atr	Atr	\N	PN D3 (2,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 13:07:47	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
78472c28-8618-42e6-b620-d9674f2a242a	RJJP270324-0633	OP071328-270324-0040	07-13-28	2024-03-27 14:50:28	MARLINA BINTI MARTO ,NY	KARYAWAN/TI	F	JL SALEMBA TENGAH	083874693982	Laras Fajri Nanda Widiiswa	4122023038	\N	\N	\N	\N	\N	\N	+	+	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	PR D4(2,1)	PR D4(2,2)	\N	\N	\N	\N	\N	RRX	\N	\N	\N	\N	\N	\N	\N	\N	\N	composite	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	MISS	\N	\N	\N	\N	\N	\N	MISS	PN D3(1,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 11:09:44	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
e2692483-5a8a-48e0-bafd-6a21a5bb9e6b	RJJP220324-0357	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023030	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9e2307e4-dbb5-4f8d-8c31-cb8ca41f8f34	RJJP210324-0369	OP071781-210324-0127	07-17-81	2024-03-21 10:25:55	KAFKA RAFAN ELFATIH, TN	PELAJAR	M	JL KRAMAT KWITANG 2 UJUNG NO 1	08161454160	Sahri Muhamad Risky	4122023043	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	ocar D4 (1,2)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	TS	Ocar D3 (1,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Vcar D3 (3,1)	\N	\N	\N	Vcar D4 (3,1)	Vcar D4 (3,2)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 13:26:05	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/ddc1190b-d941-485b-9442-0f65f01bd558.jpeg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/40204395-9d6e-4b52-95c0-9ee89f7dd267.jpeg	\N	\N	\N	\N	\N	\N	WRITE	\N
a5801a7c-da27-4277-9855-f251f5a98141	RJJP250324-0441	OP071328-250324-0223	07-13-28	2024-03-25 11:32:08	MARLINA BINTI MARTO ,NY	KARYAWAN/TI	F	JL SALEMBA TENGAH	083874693982	Faika Zahra Chairunnisa	4122023030	\N	\N	\N	\N	\N	\N	+	+	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	PN D4 (2,2)	PN D4 (2,2)	\N	\N	\N	atr	\N	rrx	\N	\N	\N	\N	\N	\N	\N	\N	Pro restorasi klas 3 RK	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	\N	\N	mis	\N	\N	\N	\N	\N	mis	PN D3 (1,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 13:43:33	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
ed967c41-3a29-49bb-ad8f-a62a8e62dfac	RJJP210324-0493	OP074096-200324-0061	07-40-96	2024-03-21 13:41:16	DODY PRIBADI, TN	SWASTA	M	JL CIBUBUR 7 GG MANGGA DUA	085693260721	Faika Zahra Chairunnisa	4122023030	\N	\N	\N	-	+	+	\N	+	+	\N	\N	\N	+	\N	\N	\N	mis	mis	mis	rrx	PN D3 (1,1)	PN D3 (2,1)	\N	PN D4 (2,2)	PN D4 (2,2)	\N	\N	rrx	PN D4 (2,2)	rrx	rrx	rrx	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	+	+	\N	\N	\N	\N	\N	+	\N	+	\N	\N	\N	\N	\N	\N	PN D4 (2,2)	PN D3 (1,1)	rrx	mis	mis	mis	\N	PN D5 (1,1)	mis	PN D3 (1,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 13:43:27	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
eb622833-1ccc-4974-aa49-7c9d00d44289	RJJP080524-0590	OP048992-080524-0171	04-89-92	2024-05-08 12:22:17	SITI KHODIJAH, NY	SWASTA	F	JALAN CEMPAKA PUTIH  BARAT XIX RT.007/007	0895321870909	Farah Alifah Rahayu	4122023031	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 13:45:40	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
95d75821-6b20-4da0-a8f2-973ab653f669	RJJP060324-0500	OP071756-060324-0050	07-17-56	2024-03-06 13:37:08	JANUAR BASTIAN MAKATUTU	KARYAWAN/TI	M	JL PERCETAKAN NEGARA X	089528874808	Karina Ivana Nariswari	4122023036	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 13:47:22	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
778df637-8206-4037-84c5-53b1615beae5	RJJP210324-0350	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023031	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6078582b-7127-4789-a28a-46cee34dd206	RJJP160524-0204	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023036	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2b949371-6b4f-462e-9ab4-836fc1409ab6	RJJP210524-0485	OP079568-210524-0014	07-95-68	2024-05-21 11:39:55	MUHAMMAD IRFAN FACHRUL RODY, TN	KARYAWAN/TI	M	PD. UNGU PERMAI BLOK AG7 / 2	081399952779	Andi Adjani Salwa Putri	4122023026	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	MVD-Car d2,s1,s1	sou	sou	sou	sou	sou	sou	sou	fr	sou	sou	M-Car d3,s2,s1	V-Car d1,s3,s1	OD-Car d5,s2,s3	M-Car d3,s1,s1	M-Car d1,s1,s1	\N	\N	\N	\N	\N	\N	\N	\N	RK kelas 4	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	fr	sou	sou	sou	sou	rrx	sou	O-car d3,s1,s1	O-Car d2,s1,s1	O-Car d2,s1,s1	O-Car d2,s1,s1	sou	sou	sou	sou	fr	RK Kelas 4	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	RK Kelas 4	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-28 01:27:13	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/b2cc5e7f-9754-42d4-9ef5-543677187856.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/8f553db1-42c7-42dc-96ae-762d57fac3d1.jpg	\N	\N	\N	\N	\N	\N	WRITE	\N
03777a93-2103-4d5a-b7a6-f3e10000fc9b	RJJP070324-0538	OP074315-070324-0227	07-43-15	2024-03-07 13:26:02	IRFAN FAUZI, TN	KARYAWAN/TI	M	DUSUN ANGGREK GALA HERAN	083823541379	Sahri Muhamad Risky	4122023043	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	D5 1,4	\N	\N	\N	D4 1,4	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 16:47:26	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/009116f0-d099-4c30-8bd9-cfa1302e638b.jpeg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/243ebd77-c5ff-4d9a-bc59-f515afcaf6bd.jpeg	\N	\N	\N	\N	\N	\N	WRITE	\N
0bf6ec2c-3ec6-4e11-93ef-25fe8f7f4f30	RJJP060324-0594	OP071611-060324-0018	07-16-11	2024-03-06 15:33:01	KEYLA GHIRIA PUTRI, NN	PELAJAR	F	JL. TANAH TINGGI SAWAH NO 8 10\\12	085781023116	Sahri Muhamad Risky	4122023043	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	D3 1,2	D3 1,2	D3 1,2	D4 1,2	\N	D4 1,3	D4 1,3	\N	\N	\N	\N	\N	D4 1,4	D3 1,3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	D4 1,2	\N	D3 1,2	\N	\N	\N	D3 1,2	D3 1,2	\N	\N	\N	\N	D3 1,2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 13:55:57	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/29adb5d3-2c14-4a0d-be7c-1366d049bcf7.jpeg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/84702da2-b0e3-42a6-b6bf-43733b60091b.jpeg	\N	\N	\N	\N	\N	\N	WRITE	\N
485df905-846c-4a03-aa9f-189bd8801511	RJJP040324-0244	OP073380-040324-0193	07-33-80	2024-03-04 08:46:40	AYASMINE VENEZIA ACHMAD, NN	PELAJAR	F	JL SWASEMBADA BARAT VIII NO 29	087870366379	Sekar Decita Ananda Iswanti	4122023044	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	--	-	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	-	\N	\N	--	-	-	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	YA	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	YA	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-28 10:00:19	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/a7f26aa9-7112-4057-8aa8-ec8b46de8d0c.png	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/849665e7-3264-4be4-8ba0-7bdc8c55e288.png	\N	\N	\N	\N	\N	\N	WRITE	\N
903407f6-2cd1-4d59-ae40-18706dd2d120	RJJP150324-0081	OP071611-150324-0050	07-16-11	2024-03-15 07:37:37	KEYLA GHIRIA PUTRI, NN	PELAJAR	F	JL. TANAH TINGGI SAWAH NO 8 10\\12	085781023116	Sahri Muhamad Risky	4122023043	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	D3 1,2	D3 1,2	D3 1,2	D4 1,2	\N	D4 1,3	D4 1,3	\N	\N	\N	\N	\N	\N	D4 1,4	D3 1,3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	D3 1,2	\N	\N	D3 1,2	\N	\N	D3 1,2	D3 1,2	\N	\N	\N	\N	D3 1,2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 14:29:47	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/4fe993c4-083e-4644-97cb-637c42d15da7.jpeg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/4a996c0a-1b64-4024-921e-a15a98eb217a.jpeg	\N	\N	\N	\N	\N	\N	WRITE	\N
024b339e-2e79-4b8a-880c-a6c39e529520	RJJP270324-0546	OP073957-270324-0540	07-39-57	2024-03-27 13:48:03	PRADNYA FAIZATUZIHAN AZKIA, NN	MAHASISWA	F	TEMBALANG PESONA ASRI L-17	085810202093	Sekar Decita Ananda Iswanti	4122023044	\N	V	V	V	V	\N	V	V	V	V	\N	V	V	V	V	\N	\N	PN (D3,2,2)	Filling komposit	Filling komposit	Filling komposit	\N	Filling komposit	Filling komposit	PSA	Filling komposit	\N	PN (D3,1,2)	PN (D3,1,1)	PN (D3,1,1)	PN (D3,1,2)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	V	V	V	V	\N	\N	V	V	V	V	\N	\N	\N	\N	\N	\N	PN (D3,2,2)	Filling komposit	PN (D3,1,2)	PR (D4,2,3)	\N	\N	Filling komposit	Filling komposit	PN (D3,1,1)	PN (D3,2,2)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-28 08:20:00	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/0297baf6-1667-4f73-969e-66f80b3cf51e.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/90a90000-7d27-45cc-bfd1-68473172428f.jpg	\N	\N	\N	\N	\N	\N	WRITE	\N
191edd3f-71d3-4991-9f24-2a6e9d7827f4	RJJP130524-0473	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023034	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
ee5c90c9-dd88-4563-aba8-ac93f7fbaec4	RJJP030524-0464	OP075572-030524-0096	07-55-72	2024-05-03 11:35:52	ATIKA RAHMA MINABARI, NY	MAHASISWA	F	JL CENDRAWASIH NO. 99	085240828311	Rayyen Alfian Juneanro	4122023042	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	O L Car D3 S1 S2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	RK KLAS 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	O Car D3 S1 S2	O Car D3 S1 S2	O Car D3 S1 S2	\N	\N	\N	O Cof rct	\N	\N	\N	\N	\N	\N	\N	\N	\N	RK KLAS 1	RK KLAS 1	RK KLAS 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	A. Mau Mengubah Sikap	2. Perlu Diperbaiki	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	YA	\N	TIDAK	\N	YA	YA	YA	YA	YA	\N	\N	\N	YA	\N	TIDAK	\N	\N	\N	\N	\N	2024-05-28 09:00:49	\N	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/fe245060-b096-4102-b9eb-d43c284b4fd5.jpeg	\N	\N	\N	\N	\N	\N	WRITE	\N
367a2c46-9894-4ec3-9424-c419ae5a9700	RJJP140524-0283	OP076902-140524-0118	07-69-02	2024-05-14 09:23:58	PUTRI AYU NURHADIZAH, NN	MAHASISWA	F	BALIMATRAMAN NO. 6	087770259814	Atika Rahma Minabari	4122023027	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	O car D3,S1,S1	O car D3,S1,S1	\N	\N	\N	\N	M car d3,s2,s1	M car d3,s2,s1	m car d3,s2,s1	\N	\N	\N	D car d3,s2,s1	D car d3,s1,s1	\N	\N	resin komposit kelas 1	resin komposit kelas 1	\N	\N	\N	\N	resin komposit kelas III	resin komposit kelas III	resin komposit kelas III	\N	\N	\N	resin komposit kelas II	resin komposit kelas II	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	A. Mau Mengubah Sikap	1. Tidak Ada Penyakit	K. 30-60 Detik	H. Jenrnih, Cair	K. 6,0-6,6	\N	H. > 5,0 ml	H. 10-12	H. 6,8-7,8	M. <= 5,5	M. Stain Biru	Ya	K. 1-2x/hr	Tidak	Tidak	Tidak	Ya	Tidak	\N	HIJAU	MERAH	KUNING	KUNING	HIJAU	A. Mau Mengubah Sikap	1. Tidak Ada Penyakit	K. 30-60 Detik	H. Jenrnih, Cair	K. 6,0-6,6	\N	H. > 5,0 ml	H. 10-12	K. 6,0-6,6	M. <= 5,5	M. Stain Biru	Ya	K. 1-2x/hr	Tidak	Tidak	Tidak	Ya	Tidak	\N	KUNING	MERAH	KUNING	KUNING	HIJAU	YA	TIDAK	TIDAK	TIDAK	TIDAK	YA	YA	YA	YA	TIDAK	YA	TIDAK	YA	TIDAK	TIDAK	TIDAK	TIDAK	TIDAK	TIDAK	YA	TIDAK	TIDAK	TIDAK	TIDAK	YA	YA	YA	YA	TIDAK	YA	TIDAK	YA	TIDAK	TIDAK	TIDAK	TIDAK	TIDAK	TIDAK	\N	2024-05-27 17:42:18	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/a1a1ce26-d1b5-44e2-a37e-a8674d713daa.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/96611bfe-8d39-4c25-9b39-2e6932301cde.jpg	Tidak	Tidak	K. 1-2x/hr	Tidak	Tidak	K. 1-2x/hr	WRITE	\N
00ed68a0-68cf-4911-a82c-b8763f37c7a3	RJJP070524-0501	OP073505-070524-0032	07-35-05	2024-05-07 11:19:17	AULIA MAULIDA FITRIANI. NN	MAHASISWA	F	JL NURUL HUDA I NO 2\r\n002/015	08990743556	Rayyen Alfian Juneanro	4122023042	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	D Car D3 S2 S1	V Car D3 S3 S1	\N	\N	\N	\N	\N	M Car D3 S2 S1	\N	\N	\N	\N	V O Car D4 S3 S1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	RK KLas 3 & 4	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	L Car D3 S3 S1	O Car D3 S1 S1	\N	\N	O Car D2 S1 S2	O Car D5 S1 S3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	A. Mau Mengubah Sikap	1. Tidak Ada Penyakit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	YA	\N	YA	YA	\N	YA	YA	YA	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-28 09:14:12	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/5942150f-fc51-4815-906f-fdf57f5657ed.jpeg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/22d885e1-adc5-413b-9aac-c97d83281225.jpeg	\N	\N	\N	\N	\N	\N	WRITE	\N
1ac28e25-0b37-436d-94fa-8603c4bd64f2	RJJP150524-0317	OP078987-150524-0314	07-89-87	2024-05-15 10:30:49	ROBI TADRIANSAH, TN	MAHASISWA	M	SINGA PERBANGSA	085742909384	Andi Adjani Salwa Putri	4122023026	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	une	sou	\N	miss	sou	sou	sou	sou	sou	sou	M-Car d3, s1, s2	miss	miss	sou	sou	une	\N	\N	GIC kelas 5	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	sou	sou	sou	sou	sou	O-Car d1, s1, s1	sou	pre	une	sou	V-Car d1,s1,s1	miss	sou	sou	sou	sou	\N	\N	\N	\N	\N	RK kelas 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-28 00:58:42	\N	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/7c99119f-66e3-4539-a24b-843b19c04739.jpg	\N	\N	\N	\N	\N	\N	WRITE	\N
1783fc11-36d9-425e-9c3b-4348efdb46d0	RJJP240524-0351	OP050397-240524-0268	05-03-97	2024-05-24 10:14:57	AYU LESTARI, NN	MAHASISWA	F	DUSUN PELITA RT 005/001	081807214216	Atika Rahma Minabari	4122023027	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	D car D3,s2,s1	O car D3,S1,S1	\N	Mis	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	resin komposit kelas II	resin komposit kelas I	\N	\N	\N	\N	\N	fraktur	\N	\N	mis	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	karies sekunder	\N	\N	O car d3,s1,s1	O car D3,s1,s1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	resin komposit kelas I	resin komposit kelas I	\N	\N	\N	\N	\N	\N	A. Mau Mengubah Sikap	1. Tidak Ada Penyakit	K. 30-60 Detik	H. Jenrnih, Cair	K. 6,0-6,6	\N	K. 3,5-5,0 ml	K. 6-9	K. 6,0-6,6	M. <= 5,5	M. Stain Biru	Ya	M. >2x/hr	Tidak	Tidak	Tidak	Tidak	Ya	\N	KUNING	MERAH	MERAH	KUNING	HIJAU	A. Mau Mengubah Sikap	1. Tidak Ada Penyakit	K. 30-60 Detik	H. Jenrnih, Cair	K. 6,0-6,6	\N	K. 3,5-5,0 ml	K. 6-9	K. 6,0-6,6	M. <= 5,5	M. Stain Biru	Ya	M. >2x/hr	Tidak	Tidak	Tidak	Tidak	Ya	\N	KUNING	MERAH	MERAH	KUNING	HIJAU	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	YA	TIDAK	TIDAK	TIDAK	TIDAK	YA	YA	YA	YA	TIDAK	YA	TIDAK	YA	TIDAK	TIDAK	TIDAK	TIDAK	TIDAK	\N	\N	2024-05-27 18:45:15	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/94e38c8a-30cd-41b4-a1da-b72c28d92368.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/477de86c-6b24-4b91-b35f-cd4a8a9b1a02.jpg	Tidak	Tidak	K. 1-2x/hr	Tidak	Tidak	M. >2x/hr	WRITE	\N
fa8331d0-ba9e-449b-b627-becd081a1e18	RJJP080524-0376	OP079123-080524-0101	07-91-23	2024-05-08 10:26:41	FARREL RAMADHAN, TN	MAHASISWA	M	JL CEMPAKA LAPANGAN TENIS NO 34 A	082298907766	Rayyen Alfian Juneanro	4122023042	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	V Car (D3 S3 S2)	V Car (D3 S3 S2)	\N	\N	\N	\N	\N	\N	V Car (D3 S3 S2)	V Car (D3 S3 S2)	V Car (D3 S3 S2)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	V Car (d3 s3 s2)	\N	\N	\N	\N	\N	\N	\N	\N	V Car (D3 S3 S2)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	A. Mau Mengubah Sikap	1. Tidak Ada Penyakit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	YA	\N	YA	\N	\N	\N	\N	YA	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-28 09:25:45	\N	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/b96af64c-2beb-4956-a00d-9620c42c151b.jpeg	\N	\N	\N	\N	\N	\N	WRITE	\N
764b1a76-4640-40d0-922b-d2211a581254	RJJP220524-0562	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023041	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
0ba60779-14ca-422a-85d2-3f3d0d534952	RJJP160524-0443	OP079568-160524-0253	07-95-68	2024-05-16 13:24:29	MUHAMMAD IRFAN FACHRUL RODY, TN	KARYAWAN/TI	M	PD. UNGU PERMAI BLOK AG7 / 2	081399952779	Atika Rahma Minabari	4122023027	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	M V car d2,s1,s1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	M car D3,S2,S1	V car D1,S3,S1	O D Car	O car D3,S1,S1	M O Car D1,S1,S1	resin komposit kela 2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	resin komposit kelas 2	resin komposit kelas 5	resin komposit kelas 1	resin komposit kelas 1	resin komposit kelas 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Fraktur	\N	\N	\N	\N	RRX	O car D2,S1,S1	O car D3,S1,S1	o car d2,s1,s1	o car d2,s1,s1	o car d2,s1,s1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	ekstraksi	resin komposit kelas 1	resin komposit kelas 1	resin komposit kelas 1	resin komposit kelas 1	resin komposit kelas 1	\N	\N	\N	\N	\N	B. Mungkin Mengubah Sikap	1. Tidak Ada Penyakit	K. 30-60 Detik	K. Berbusa	M. 5,0-5,8	\N	K. 3,5-5,0 ml	K. 6-9	M. 5,0-5,8	M. <= 5,5	M. Stain Biru	Ya	M. >2x/hr	Tidak	Tidak	Ya	Ya	Tidak	\N	KUNING	MERAH	MERAH	KUNING	KUNING	A. Mau Mengubah Sikap	1. Tidak Ada Penyakit	K. 30-60 Detik	K. Berbusa	M. 5,0-5,8	\N	K. 3,5-5,0 ml	K. 6-9	M. 5,0-5,8	M. <= 5,5	M. Stain Biru	Ya	M. >2x/hr	Tidak	Tidak	Ya	Ya	Tidak	\N	KUNING	MERAH	MERAH	KUNING	KUNING	TIDAK	TIDAK	TIDAK	TIDAK	TIDAK	YA	YA	YA	YA	TIDAK	YA	TIDAK	YA	TIDAK	TIDAK	TIDAK	TIDAK	TIDAK	TIDAK	TIDAK	TIDAK	TIDAK	TIDAK	TIDAK	YA	YA	YA	YA	TIDAK	YA	TIDAK	YA	TIDAK	TIDAK	TIDAK	TIDAK	TIDAK	TIDAK	\N	2024-05-27 20:39:27	\N	\N	Tidak	Tidak	M. >2x/hr	Tidak	Tidak	M. >2x/hr	WRITE	\N
4221a41a-d26d-447a-9aa8-6fda2024ecb7	RJJP030524-0446	OP074083-030524-0079	07-40-83	2024-05-03 11:00:57	JIHAN AR ROHIM, NY	MAHASISWA	F	JL. BINTARA RAYA AA 99/4	085707705388	Andi Adjani Salwa Putri	4122023026	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	une	sou	sou	sou	sou	sou	sou	sou	sou	sou	sou	sou	sou	sou	OL-Car d3, s1, s1	une	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	sou	sou	sou	sou	sou	O-Car d3, s1, s1	O-Car d3, s1, s1	une	une	O-Car d3, s1, s1	O-Car d3, s1, s1	sou	sou	sou	sou	sou	\N	\N	\N	\N	\N	RK kelas 1	RK kelas 1	\N	\N	RK kelas 1	RK kelas 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	A. Mau Mengubah Sikap	2. Perlu Diperbaiki	H. < dari 30 Detik	K. Berbusa	H. 6,8-7,8	\N	H. > 5,0 ml	\N	H. 6,8-7,8	\N	\N	Ya	K. 1-2x/hr	Tidak	Tidak	Tidak	Ya	Ya	\N	HIJAU	\N	KUNING	KUNING	KUNING	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-28 00:46:16	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/94e7e1da-3247-489f-bfd0-bfd916ca74ab.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/a227e783-fcac-4084-b294-2814cd84760f.jpg	\N	\N	\N	Tidak	Tidak	K. 1-2x/hr	WRITE	\N
c9cc4e55-33cb-4663-baf2-eb7c82cf3c8a	RJJP220524-0701	OP079568-210524-0081	07-95-68	2024-05-22 17:26:15	MUHAMMAD IRFAN FACHRUL RODY, TN	KARYAWAN/TI	M	PD. UNGU PERMAI BLOK AG7 / 2	081399952779	Atika Rahma Minabari	4122023027	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	MVO Car d2,s1,s1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	M Car d3,s2,1	\N	O car	MO car D3,S2,3	MO car d3,s1,s1	resin komposit kelas 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	resin komposit kelas 2	\N	resin komposit kelas 1	resin komposit kelas 1	resin komposit kelas 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	FR	\N	\N	\N	\N	RRX	D Car d2,s2,s2	O car d3,s1,s1	O car d2,s1,s1	O car d2,s1s1	Ocar d2,s1,s1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	resin komposit kelas 1	resin komposit kelas 1	resin komposit kelas 1	\N	\N	\N	\N	\N	A. Mau Mengubah Sikap	1. Tidak Ada Penyakit	K. 30-60 Detik	K. Berbusa	K. 6,0-6,6	\N	K. 3,5-5,0 ml	K. 6-9	K. 6,0-6,6	K. 6,0-6,5	M. Stain Biru	Ya	K. 1-2x/hr	Tidak	Tidak	Ya	Ya	Tidak	\N	KUNING	MERAH	KUNING	KUNING	KUNING	A. Mau Mengubah Sikap	1. Tidak Ada Penyakit	K. 30-60 Detik	K. Berbusa	K. 6,0-6,6	\N	K. 3,5-5,0 ml	K. 6-9	K. 6,0-6,6	K. 6,0-6,5	M. Stain Biru	Ya	K. 1-2x/hr	Tidak	Tidak	Ya	Ya	Ya	\N	KUNING	MERAH	KUNING	KUNING	KUNING	YA	TIDAK	TIDAK	TIDAK	TIDAK	YA	YA	YA	YA	TIDAK	YA	TIDAK	YA	TIDAK	TIDAK	TIDAK	TIDAK	TIDAK	TIDAK	YA	TIDAK	TIDAK	TIDAK	TIDAK	YA	YA	YA	YA	TIDAK	YA	TIDAK	YA	TIDAK	TIDAK	TIDAK	TIDAK	TIDAK	TIDAK	\N	2024-05-27 21:18:45	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/ff3e0665-ac49-444b-a42e-abbf0901c645.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/bec1929f-8b1d-4880-a08f-e5449e6368ac.jpg	Tidak	Tidak	K. 1-2x/hr	Tidak	Tidak	K. 1-2x/hr	WRITE	\N
757ab023-cc40-4bcf-99a3-69b96337f710	RJJP020524-0546	OP075572-020524-0139	07-55-72	2024-05-02 11:53:53	ATIKA RAHMA MINABARI, NY	MAHASISWA	F	JL CENDRAWASIH NO. 99	085240828311	Ivo Resky Primigo	4122023033	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OL Car	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	O Car	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	O Car	\N	O Car	\N	\N	RCT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Resin komposit Klas 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 21:37:08	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
05e8b6cb-e95c-45e5-b2b8-a36dc921196d	RJJP200324-0448	OP071756-200324-0114	07-17-56	2024-03-20 13:05:22	JANUAR BASTIAN MAKATUTU	KARYAWAN/TI	M	JL PERCETAKAN NEGARA X	089528874808	Karina Ivana Nariswari	4122023036	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	PN, D3(1,3)	\N	\N	\N	PN,D3 (2,2)	PN, D3,2,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Restorasi komposit	\N	\N	\N	Restorasi komposit	Restorasi komposit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	PN D2 (1,1)	PN D2 (1,1)	\N	\N	PN D3 (1,1)	PN D2 (1,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Restorasi komposit	Restorasi komposit	\N	\N	Restorasi komposit	Restorasi komposit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 23:16:01	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
2938249f-54c8-4b9f-a252-6d4fbcccd2ca	RJJP100524-0467	OP050475-100524-0219	05-04-75	2024-05-10 13:09:15	SHAFA ADILLA PUTRI MAHESA, NN	MAHASISWA	F	JL PDAM PAM JAYA NO 21 RT 010/003	081219977407	Andi Adjani Salwa Putri	4122023026	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	une	sou	sou	sou	sou	sou	sou	sou	sou	sou	sou	sou	sou	sou	sou	une	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	sou	sou	sou	sou	sou	sou	sou	une	une	sou	D-Car d2, s2, s2	sou	sou	sou	sou	sou	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	RK Kelas 2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-28 01:08:02	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/6034b87d-307e-4c3c-b3cd-8113faf7697a.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/ebc8182a-955f-4eeb-9606-0a8f665d4826.jpg	\N	\N	\N	\N	\N	\N	WRITE	\N
fb5678cc-9351-4be4-bb2b-dbc13f92a02d	RJJP200324-0143	OP074181-200324-0024	07-41-81	2024-03-20 08:22:17	AGNES SUKARSIH, NY	GURU	F	JL. ANGIN SEJUK IV NO. 31	089512303944	Sekar Decita Ananda Iswanti	4122023044	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 23:39:10	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/b1715b25-6c5e-4f4e-a8d4-5946c751c27d.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/58864477-4146-4d39-b88b-355b703da341.jpg	\N	\N	\N	\N	\N	\N	WRITE	\N
0df7000e-d65d-407d-80c1-1b10046ad24e	RJJP270324-0467	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023041	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 21:56:42	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/5f6261e4-01c6-489e-add1-67f5f7d3f341.heic	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
026ab7ae-a532-4014-a909-9c3111756fbe	RJJP140524-0506	OP079568-140524-0045	07-95-68	2024-05-14 13:42:11	MUHAMMAD IRFAN FACHRUL RODY, TN	KARYAWAN/TI	M	PD. UNGU PERMAI BLOK AG7 / 2	081399952779	Andi Adjani Salwa Putri	4122023026	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	MVD-Car (d2, s1, s1)	sou	sou	sou	sou	sou	sou	sou	D-Car d3,s2,s1	sou	decay	M-Car d3,s2,s1	V-Car d1,s2,s3	OD-Car d5,s2,s3	M-Car d3,s1,s1	M-Car d1,s1,s1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	RK kelas 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	fr	sou	sou	sou	sou	rrx	MO-Car d3,s2,s2	MO-Car d3,s1,s1	O-Car d3,s1,s1	O-Car d2,s1,s1	O-Car d2,s1,s1	sou	sou	sou	sou	fr	RK kelas 4	\N	\N	\N	\N	\N	RK Kelas 2	\N	\N	\N	\N	\N	\N	\N	\N	RK kelas 4	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-28 01:19:15	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/20140e02-1070-45d0-ba1c-94f99b8daac4.HEIC	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/konservasi/reparasi/beofre/e913f48f-95d9-4eb5-b03c-54a8abb0a669.jpg	\N	\N	\N	\N	\N	\N	WRITE	\N
2490220d-7080-496c-b782-45f64b536969	RJJP220324-0356	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023030	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
86ff0da1-b64b-4b83-92ba-5e798e6679bb	RJJP130524-0494	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023026	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3cf82728-e862-4b4d-a451-ade2de7616b7	RJJP260324-0450	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023030	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
de127d9f-d414-46de-a365-b754998c996e	RJJP270224-0349	OP071756-270224-0086	07-17-56	2024-02-27 09:43:20	JANUAR BASTIAN MAKATUTU	KARYAWAN/TI	M	JL PERCETAKAN NEGARA X	089528874808	Karina Ivana Nariswari	4122023036	+++=++	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	PN, D3 (1,3)	\N	\N	\N	PN, D3 (2,2)	PN, D3 (2,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	PN D2(1,1)	PN,D2 (1,1)	\N	\N	PN, D2(1,1)	PN, D3 (1,1)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-28 08:11:55	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
5cb40132-c9bc-4f55-8eb9-ea8f3b6cfda4	RJJP200324-0195	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023030	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
e676ed53-2733-4938-9841-9e66a69c8c81	RJJP050424-0235	OP073957-050424-0077	07-39-57	2024-04-05 09:25:20	PRADNYA FAIZATUZIHAN AZKIA, NN	MAHASISWA	F	TEMBALANG PESONA ASRI L-17	085810202093	Sekar Decita Ananda Iswanti	4122023044	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-28 08:21:44	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
b1b5fb0a-65dc-4090-9351-5da0b361b9c7	RJJP050324-0481	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023044	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
d440a0f4-1d5c-48d6-9623-ff57041da3e5	RJJP140524-0206	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023026	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8d11519b-99e6-4109-8e5e-e01c5f18c2c3	RJJP130524-0458	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023033	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
47570864-97af-442c-87b3-9c94391fd790	RJJP200324-0301	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023043	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
f2541d7b-743d-4206-98b8-290c3bffd954	RJJP270324-0516	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023036	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
457b0e5c-fbde-4231-8909-6d2370ad0ac4	RJJP030424-0306	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023044	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
37ae6908-b0b0-4a08-b61a-a4c41cd79668	RJJP240424-0386	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023044	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
60b254d1-47a2-46b5-b407-247413491070	RJJP300524-0266	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023032	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- TOC entry 3712 (class 0 OID 16455)
-- Dependencies: 220
-- Data for Name: emrortodonsies; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.emrortodonsies (id, noregister, noepisode, operator, nim, pembimbing, tanggal, namapasien, suku, umur, jeniskelamin, alamat, telepon, pekerjaan, rujukandari, namaayah, sukuayah, umurayah, namaibu, sukuibu, umuribu, pekerjaanorangtua, alamatorangtua, pendaftaran, pencetakan, pemasanganalat, waktuperawatan_retainer, keluhanutama, kelainanendoktrin, penyakitpadamasaanak, alergi, kelainansaluranpernapasan, tindakanoperasi, gigidesidui, gigibercampur, gigipermanen, durasi, frekuensi, intensitas, kebiasaanjelekketerangan, riwayatkeluarga, ayah, ibu, saudara, riwayatkeluargaketerangan, jasmani, mental, tinggibadan, beratbadan, indeksmassatubuh, statusgizi, kategori, lebarkepala, panjangkepala, indekskepala, bentukkepala, panjangmuka, lebarmuka, indeksmuka, bentukmuka, bentuk, profilmuka, senditemporomandibulat_tmj, tmj_keterangan, bibirposisiistirahat, tunusototmastikasi, tunusototmastikasi_keterangan, tunusototbibir, tunusototbibir_keterangan, freewayspace, pathofclosure, higienemulutohi, polaatrisi, regio, lingua, intraoral_lainlain, palatumvertikal, palatumlateral, gingiva, gingiva_keterangan, mukosa, mukosa_keterangan, frenlabiisuperior, frenlabiiinferior, frenlingualis, ketr, tonsila, fonetik, image_pemeriksaangigi, tampakdepantakterlihatgigi, fotomuka_bentukmuka, tampaksamping, fotomuka_profilmuka, tampakdepansenyumterlihatgigi, tampakmiring, tampaksampingkanan, tampakdepan, tampaksampingkiri, tampakoklusalatas, tampakoklusalbawah, bentuklengkunggigi_ra, bentuklengkunggigi_rb, malposisigigiindividual_rahangatas_kanan1, malposisigigiindividual_rahangatas_kanan2, malposisigigiindividual_rahangatas_kanan3, malposisigigiindividual_rahangatas_kanan4, malposisigigiindividual_rahangatas_kanan5, malposisigigiindividual_rahangatas_kanan6, malposisigigiindividual_rahangatas_kanan7, malposisigigiindividual_rahangatas_kiri1, malposisigigiindividual_rahangatas_kiri2, malposisigigiindividual_rahangatas_kiri3, malposisigigiindividual_rahangatas_kiri4, malposisigigiindividual_rahangatas_kiri5, malposisigigiindividual_rahangatas_kiri6, malposisigigiindividual_rahangatas_kiri7, malposisigigiindividual_rahangbawah_kanan1, malposisigigiindividual_rahangbawah_kanan2, malposisigigiindividual_rahangbawah_kanan3, malposisigigiindividual_rahangbawah_kanan4, malposisigigiindividual_rahangbawah_kanan5, malposisigigiindividual_rahangbawah_kanan6, malposisigigiindividual_rahangbawah_kanan7, malposisigigiindividual_rahangbawah_kiri1, malposisigigiindividual_rahangbawah_kiri2, malposisigigiindividual_rahangbawah_kiri3, malposisigigiindividual_rahangbawah_kiri4, malposisigigiindividual_rahangbawah_kiri5, malposisigigiindividual_rahangbawah_kiri6, malposisigigiindividual_rahangbawah_kiri7, overjet, overbite, palatalbite, deepbite, anterior_openbite, edgetobite, anterior_crossbite, posterior_openbite, scissorbite, cusptocuspbite, relasimolarpertamakanan, relasimolarpertamakiri, relasikaninuskanan, relasikaninuskiri, garistengahrahangbawahterhadaprahangatas, garisinterinsisivisentralterhadapgaristengahrahangra, garisinterinsisivisentralterhadapgaristengahrahangra_mm, garisinterinsisivisentralterhadapgaristengahrahangrb, garisinterinsisivisentralterhadapgaristengahrahangrb_mm, lebarmesiodistalgigi_rahangatas_kanan1, lebarmesiodistalgigi_rahangatas_kanan2, lebarmesiodistalgigi_rahangatas_kanan3, lebarmesiodistalgigi_rahangatas_kanan4, lebarmesiodistalgigi_rahangatas_kanan5, lebarmesiodistalgigi_rahangatas_kanan6, lebarmesiodistalgigi_rahangatas_kanan7, lebarmesiodistalgigi_rahangatas_kiri1, lebarmesiodistalgigi_rahangatas_kiri2, lebarmesiodistalgigi_rahangatas_kiri3, lebarmesiodistalgigi_rahangatas_kiri4, lebarmesiodistalgigi_rahangatas_kiri5, lebarmesiodistalgigi_rahangatas_kiri6, lebarmesiodistalgigi_rahangatas_kiri7, lebarmesiodistalgigi_rahangbawah_kanan1, lebarmesiodistalgigi_rahangbawah_kanan2, lebarmesiodistalgigi_rahangbawah_kanan3, lebarmesiodistalgigi_rahangbawah_kanan4, lebarmesiodistalgigi_rahangbawah_kanan5, lebarmesiodistalgigi_rahangbawah_kanan6, lebarmesiodistalgigi_rahangbawah_kanan7, lebarmesiodistalgigi_rahangbawah_kiri1, lebarmesiodistalgigi_rahangbawah_kiri2, lebarmesiodistalgigi_rahangbawah_kiri3, lebarmesiodistalgigi_rahangbawah_kiri4, lebarmesiodistalgigi_rahangbawah_kiri5, lebarmesiodistalgigi_rahangbawah_kiri6, lebarmesiodistalgigi_rahangbawah_kiri7, skemafotooklusalgigidarimodelstudi, jumlahmesiodistal, jarakp1p2pengukuran, jarakp1p2perhitungan, diskrepansip1p2_mm, diskrepansip1p2, jarakm1m1pengukuran, jarakm1m1perhitungan, diskrepansim1m2_mm, diskrepansim1m2, diskrepansi_keterangan, jumlahlebarmesiodistalgigidarim1m1, jarakp1p1tonjol, indeksp, lengkunggigiuntukmenampunggigigigi, jarakinterfossacaninus, indeksfc, lengkungbasaluntukmenampunggigigigi, inklinasigigigigiregioposterior, metodehowes_keterangan, aldmetode, overjetawal, overjetakhir, rahangatasdiskrepansi, rahangbawahdiskrepansi, fotosefalometri, fotopanoramik, maloklusiangleklas, hubunganskeletal, malrelasi, malposisi, estetik, dental, skeletal, fungsipenguyahanal, crowding, spacing, protrusif, retrusif, malposisiindividual, maloklusi_crossbite, maloklusi_lainlain, maloklusi_lainlainketerangan, rapencabutan, raekspansi, ragrinding, raplataktif, rbpencabutan, rbekspansi, rbgrinding, rbplataktif, analisisetiologimaloklusi, pasiendirujukkebagian, pencarianruanguntuk, koreksimalposisigigiindividual, retensi, pencarianruang, koreksimalposisigigiindividual_rahangatas, koreksimalposisigigiindividual_rahangbawah, intruksipadapasien, retainer, gambarplataktif_rahangatas, gambarplataktif_rahangbawah, keterangangambar, prognosis, prognosis_a, prognosis_b, prognosis_c, indikasiperawatan, created_at, updated_at, status_emr, status_penilaian) FROM stdin;
0b2b1e89-4f22-47ca-b48e-82c80992fc51	RJJP190424-0325	\N	\N	4122023034	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- TOC entry 3713 (class 0 OID 16460)
-- Dependencies: 221
-- Data for Name: emrpedodontie_behaviorratings; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.emrpedodontie_behaviorratings (id, emrid, frankscale, beforetreatment, duringtreatment, created_at, updated_at, userentryname) FROM stdin;
\.


--
-- TOC entry 3714 (class 0 OID 16465)
-- Dependencies: 222
-- Data for Name: emrpedodontie_treatmenplans; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.emrpedodontie_treatmenplans (id, emrid, oralfinding, diagnosis, treatmentplanning, userentryname, updated_at, created_at, userentry, datetreatmentplanentry) FROM stdin;
e354713b-b950-440d-bfd5-b70fcef69b76	6a3bb3e7-f0b7-4674-ab4a-a8beee098d26	TEST ORALFINDING-1	TEST DIAGNOSING-1	TEST TREATMENTPLANNING-1	Ivan Hasan	2024-04-03 10:00:02	2024-04-03 10:00:02	161fe372-52ed-4f29-adba-30855ab47d14	2024-02-24 00:00:00
27fd4f97-4a26-413c-9bbd-e7b59cc2f01a	6a3bb3e7-f0b7-4674-ab4a-a8beee098d26	TEST ORALFINDING-2	TEST DIAGNOSIS-2	TEST TREATMENTPLAN-2	Ivan Hasan	2024-04-03 10:00:40	2024-04-03 10:00:40	161fe372-52ed-4f29-adba-30855ab47d14	2024-02-24 00:00:00
2bc08ce3-b495-497d-aa48-e6f5be1941b5	a5651331-61f3-4373-9979-dd59de753225	e: qwww f: www def: wwww Rahang Bawah e: ggdsdgfsgfshsjfjsfdbxbqwww f: www def: wwww Rahang Bawah e: qwww f: www def: wwww Rahang Bawah	e: qwww f: www def: wwww Rahang Bawah e: qwwcvbxbvw f: www def: wwww Rahang Bawah	e: qwww f: www def: wwww Rahang Bawah e: qwwwbxcbxb f: www def: wwww Rahang Bawah e: qwww f: www def: wwww Rahang Bawah	Qanita Regina Maharani	2024-04-23 16:06:26	2024-04-23 16:06:15	d2e5c81f-42ab-445a-8cd8-f8be8063a9c4	2024-02-24 00:00:00
\.


--
-- TOC entry 3715 (class 0 OID 16470)
-- Dependencies: 223
-- Data for Name: emrpedodontie_treatmens; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.emrpedodontie_treatmens (id, emrid, datetreatment, itemtreatment, userentryname, updated_at, created_at, supervisorname, supervisorvalidate, userentry, supervisousername) FROM stdin;
8b72e318-f9bf-4571-9709-9091b70cd6bc	6a3bb3e7-f0b7-4674-ab4a-a8beee098d26	2024-03-04 00:00:00	TESTER	Ivan Hasan	2024-04-03 10:05:42	2024-04-03 10:02:29	\N	\N	161fe372-52ed-4f29-adba-30855ab47d14	\N
\.


--
-- TOC entry 3716 (class 0 OID 16475)
-- Dependencies: 224
-- Data for Name: emrpedodonties; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.emrpedodonties (id, tanggalmasuk, nim, namamahasiswa, tahunklinik, namasupervisor, tandatangan, namapasien, jeniskelamin, alamatpasien, usiapasien, pendidikan, tgllahirpasien, namaorangtua, telephone, pekerjaan, dokteranak, alamatpekerjaan, telephonedranak, anamnesis, noregister, noepisode, physicalgrowth, heartdesease, created_at, updated_at, bruiseeasily, anemia, hepatitis, allergic, takinganymedicine, takinganymedicineobat, beenhospitalized, beenhospitalizedalasan, toothache, childtoothache, firstdental, unfavorabledentalexperience, "where", reason, fingersucking, diffycultyopeningsjaw, howoftenbrushtooth, howoftenbrushtoothkali, usefluoridepasta, fluoridetreatmen, ifyes, bilateralsymmetry, asymmetry, straight, convex, concave, lipsseal, clicking, clickingleft, clickingright, pain, painleft, painright, bodypostur, gingivitis, stomatitis, dentalanomali, prematurloss, overretainedprimarytooth, odontogramfoto, gumboil, stageofdentition, franklscale_definitelynegative_before_treatment, franklscale_definitelynegative_during_treatment, franklscale_negative_before_treatment, franklscale_negative_during_treatment, franklscale_positive_before_treatment, franklscale_positive_during_treatment, franklscale_definitelypositive_before_treatment, franklscale_definitelypositive_during_treatment, buccal_18, buccal_17, buccal_16, buccal_15, buccal_14, buccal_13, buccal_12, buccal_11, buccal_21, buccal_22, buccal_23, buccal_24, buccal_25, buccal_26, buccal_27, buccal_28, palatal_55, palatal_54, palatal_53, palatal_52, palatal_51, palatal_61, palatal_62, palatal_63, palatal_64, palatal_65, buccal_85, buccal_84, buccal_83, buccal_82, buccal_81, buccal_71, buccal_72, buccal_73, buccal_74, buccal_75, palatal_48, palatal_47, palatal_46, palatal_45, palatal_44, palatal_43, palatal_42, palatal_41, palatal_31, palatal_32, palatal_33, palatal_34, palatal_35, palatal_36, palatal_37, palatal_38, dpalatal, epalatal, fpalatal, defpalatal, dlingual, elingual, flingual, deflingual, status_emr, status_penilaian) FROM stdin;
d380c4cf-a18b-4703-ac3a-e6292ec2698f	\N	4122023034	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	RJJP290524-0308	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
cf203318-6fec-4761-b48d-e46df0ab54fb	\N	4122023034	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	RJJP290524-0281	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- TOC entry 3717 (class 0 OID 16480)
-- Dependencies: 225
-- Data for Name: emrperiodontie_soaps; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.emrperiodontie_soaps (id, datesoap, terapi_s, terapi_o, terapi_a, terapi_p, user_entry, user_entry_name, user_verify, user_verify_name, created_at, updated_at, idemr, active, date_verify) FROM stdin;
49012432-e9e4-43d3-8768-45b230c1ba71	2024-04-23 16:34:51	dfasdaasddddddddddddddddddddddddddddavsxcvcvbxbxcbb	dasdadasdasdddddddddddddddddddddddddddddddddddddddd	sadadsadaaaaaaaaasadadadsadadadadasda	dasdasdadadadadadadadadadadad	4122023041	Qanita Regina Maharani	\N	\N	\N	2024-04-23 16:35:02	75fb5300-1a77-45a5-80c3-47000435e726	1	\N
\.


--
-- TOC entry 3718 (class 0 OID 16486)
-- Dependencies: 226
-- Data for Name: emrperiodonties; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.emrperiodonties (id, nama_mahasiswa, npm, tahun_klinik, opsi_imagemahasiswa, noregister, noepisode, no_rekammedik, kasus_pasien, tanggal_pemeriksaan, pendidikan_pasien, nama_pasien, umur_pasien, jenis_kelamin_pasien, alamat, no_telephone_pasien, pemeriksa, operator1, operator2, operator3, operator4, konsuldari, keluhanutama, anamnesis, gusi_mudah_berdarah, gusi_mudah_berdarah_lainlain, penyakit_sistemik, penyakit_sistemik_bilaada, penyakit_sistemik_obat, diabetes_melitus, diabetes_melituskadargula, merokok, merokok_perhari, merokok_tahun_awal, merokok_tahun_akhir, gigi_pernah_tanggal_dalam_keadaan_baik, keadaan_umum, tekanan_darah, extra_oral, intra_oral, oral_hygiene_bop, oral_hygiene_ci, oral_hygiene_pi, oral_hygiene_ohis, kesimpulan_ohis, rakn_keaadan_gingiva, rakn_karang_gigi, rakn_oklusi, rakn_artikulasi, rakn_abrasi_atrisi_abfraksi, ram_keaadan_gingiva, ram_karang_gigi, ram_oklusi, ram_artikulasi, ram_abrasi_atrisi_abfraksi, rakr_keaadan_gingiva, rakr_karang_gigi, rakr_oklusi, rakr_artikulasi, rakr_abrasi_atrisi_abfraksi, rbkn_keaadan_gingiva, rbkn_karang_gigi, rbkn_oklusi, rbkn_artikulasi, rbkn_abrasi_atrisi_abfraksi, rbm_keaadan_gingiva, rbm_karang_gigi, rbm_oklusi, rbm_artikulasi, rbm_abrasi_atrisi_abfraksi, rbkr_keaadan_gingiva, rbkr_karang_gigi, rbkr_oklusi, rbkr_artikulasi, rbkr_abrasi_atrisi_abfraksi, rakn_1_v, rakn_1_g, rakn_1_pm, rakn_1_pb, rakn_1_pd, rakn_1_pp, rakn_1_o, rakn_1_r, rakn_1_la, rakn_1_mp, rakn_1_bop, rakn_1_tk, rakn_1_fi, rakn_1_k, rakn_1_t, rakn_2_v, rakn_2_g, rakn_2_pm, rakn_2_pb, rakn_2_pd, rakn_2_pp, rakn_2_o, rakn_2_r, rakn_2_la, rakn_2_mp, rakn_2_bop, rakn_2_tk, rakn_2_fi, rakn_2_k, rakn_2_t, rakn_3_v, rakn_3_g, rakn_3_pm, rakn_3_pb, rakn_3_pd, rakn_3_pp, rakn_3_o, rakn_3_r, rakn_3_la, rakn_3_mp, rakn_3_bop, rakn_3_tk, rakn_3_fi, rakn_3_k, rakn_3_t, rakn_4_v, rakn_4_g, rakn_4_pm, rakn_4_pb, rakn_4_pd, rakn_4_pp, rakn_4_o, rakn_4_r, rakn_4_la, rakn_4_mp, rakn_4_bop, rakn_4_tk, rakn_4_fi, rakn_4_k, rakn_4_t, rakn_5_v, rakn_5_g, rakn_5_pm, rakn_5_pb, rakn_5_pd, rakn_5_pp, rakn_5_o, rakn_5_r, rakn_5_la, rakn_5_mp, rakn_5_bop, rakn_5_tk, rakn_5_fi, rakn_5_k, rakn_5_t, rakn_6_v, rakn_6_g, rakn_6_pm, rakn_6_pb, rakn_6_pd, rakn_6_pp, rakn_6_o, rakn_6_r, rakn_6_la, rakn_6_mp, rakn_6_bop, rakn_6_tk, rakn_6_fi, rakn_6_k, rakn_6_t, rakn_7_v, rakn_7_g, rakn_7_pm, rakn_7_pb, rakn_7_pd, rakn_7_pp, rakn_7_o, rakn_7_r, rakn_7_la, rakn_7_mp, rakn_7_bop, rakn_7_tk, rakn_7_fi, rakn_7_k, rakn_7_t, rakn_8_v, rakn_8_g, rakn_8_pm, rakn_8_pb, rakn_8_pd, rakn_8_pp, rakn_8_o, rakn_8_r, rakn_8_la, rakn_8_mp, rakn_8_bop, rakn_8_tk, rakn_8_fi, rakn_8_k, rakn_8_t, rakr_1_v, rakr_1_g, rakr_1_pm, rakr_1_pb, rakr_1_pd, rakr_1_pp, rakr_1_o, rakr_1_r, rakr_1_la, rakr_1_mp, rakr_1_bop, rakr_1_tk, rakr_1_fi, rakr_1_k, rakr_1_t, rakr_2_v, rakr_2_g, rakr_2_pm, rakr_2_pb, rakr_2_pd, rakr_2_pp, rakr_2_o, rakr_2_r, rakr_2_la, rakr_2_mp, rakr_2_bop, rakr_2_tk, rakr_2_fi, rakr_2_k, rakr_2_t, rakr_3_v, rakr_3_g, rakr_3_pm, rakr_3_pb, rakr_3_pd, rakr_3_pp, rakr_3_o, rakr_3_r, rakr_3_la, rakr_3_mp, rakr_3_bop, rakr_3_tk, rakr_3_fi, rakr_3_k, rakr_3_t, rakr_4_v, rakr_4_g, rakr_4_pm, rakr_4_pb, rakr_4_pd, rakr_4_pp, rakr_4_o, rakr_4_r, rakr_4_la, rakr_4_mp, rakr_4_bop, rakr_4_tk, rakr_4_fi, rakr_4_k, rakr_4_t, rakr_5_v, rakr_5_g, rakr_5_pm, rakr_5_pb, rakr_5_pd, rakr_5_pp, rakr_5_o, rakr_5_r, rakr_5_la, rakr_5_mp, rakr_5_bop, rakr_5_tk, rakr_5_fi, rakr_5_k, rakr_5_t, rakr_6_v, rakr_6_g, rakr_6_pm, rakr_6_pb, rakr_6_pd, rakr_6_pp, rakr_6_o, rakr_6_r, rakr_6_la, rakr_6_mp, rakr_6_bop, rakr_6_tk, rakr_6_fi, rakr_6_k, rakr_6_t, rakr_7_v, rakr_7_g, rakr_7_pm, rakr_7_pb, rakr_7_pd, rakr_7_pp, rakr_7_o, rakr_7_r, rakr_7_la, rakr_7_mp, rakr_7_bop, rakr_7_tk, rakr_7_fi, rakr_7_k, rakr_7_t, rakr_8_v, rakr_8_g, rakr_8_pm, rakr_8_pb, rakr_8_pd, rakr_8_pp, rakr_8_o, rakr_8_r, rakr_8_la, rakr_8_mp, rakr_8_bop, rakr_8_tk, rakr_8_fi, rakr_8_k, rakr_8_t, rbkn_1_v, rbkn_1_g, rbkn_1_pm, rbkn_1_pb, rbkn_1_pd, rbkn_1_pp, rbkn_1_o, rbkn_1_r, rbkn_1_la, rbkn_1_mp, rbkn_1_bop, rbkn_1_tk, rbkn_1_fi, rbkn_1_k, rbkn_1_t, rbkn_2_v, rbkn_2_g, rbkn_2_pm, rbkn_2_pb, rbkn_2_pd, rbkn_2_pp, rbkn_2_o, rbkn_2_r, rbkn_2_la, rbkn_2_mp, rbkn_2_bop, rbkn_2_tk, rbkn_2_fi, rbkn_2_k, rbkn_2_t, rbkn_3_v, rbkn_3_g, rbkn_3_pm, rbkn_3_pb, rbkn_3_pd, rbkn_3_pp, rbkn_3_o, rbkn_3_r, rbkn_3_la, rbkn_3_mp, rbkn_3_bop, rbkn_3_tk, rbkn_3_fi, rbkn_3_k, rbkn_3_t, rbkn_4_v, rbkn_4_g, rbkn_4_pm, rbkn_4_pb, rbkn_4_pd, rbkn_4_pp, rbkn_4_o, rbkn_4_r, rbkn_4_la, rbkn_4_mp, rbkn_4_bop, rbkn_4_tk, rbkn_4_fi, rbkn_4_k, rbkn_4_t, rbkn_5_v, rbkn_5_g, rbkn_5_pm, rbkn_5_pb, rbkn_5_pd, rbkn_5_pp, rbkn_5_o, rbkn_5_r, rbkn_5_la, rbkn_5_mp, rbkn_5_bop, rbkn_5_tk, rbkn_5_fi, rbkn_5_k, rbkn_5_t, rbkn_6_v, rbkn_6_g, rbkn_6_pm, rbkn_6_pb, rbkn_6_pd, rbkn_6_pp, rbkn_6_o, rbkn_6_r, rbkn_6_la, rbkn_6_mp, rbkn_6_bop, rbkn_6_tk, rbkn_6_fi, rbkn_6_k, rbkn_6_t, rbkn_7_v, rbkn_7_g, rbkn_7_pm, rbkn_7_pb, rbkn_7_pd, rbkn_7_pp, rbkn_7_o, rbkn_7_r, rbkn_7_la, rbkn_7_mp, rbkn_7_bop, rbkn_7_tk, rbkn_7_fi, rbkn_7_k, rbkn_7_t, rbkn_8_v, rbkn_8_g, rbkn_8_pm, rbkn_8_pb, rbkn_8_pd, rbkn_8_pp, rbkn_8_o, rbkn_8_r, rbkn_8_la, rbkn_8_mp, rbkn_8_bop, rbkn_8_tk, rbkn_8_fi, rbkn_8_k, rbkn_8_t, rbkr_1_v, rbkr_1_g, rbkr_1_pm, rbkr_1_pb, rbkr_1_pd, rbkr_1_pp, rbkr_1_o, rbkr_1_r, rbkr_1_la, rbkr_1_mp, rbkr_1_bop, rbkr_1_tk, rbkr_1_fi, rbkr_1_k, rbkr_1_t, rbkr_2_v, rbkr_2_g, rbkr_2_pm, rbkr_2_pb, rbkr_2_pd, rbkr_2_pp, rbkr_2_o, rbkr_2_r, rbkr_2_la, rbkr_2_mp, rbkr_2_bop, rbkr_2_tk, rbkr_2_fi, rbkr_2_k, rbkr_2_t, rbkr_3_v, rbkr_3_g, rbkr_3_pm, rbkr_3_pb, rbkr_3_pd, rbkr_3_pp, rbkr_3_o, rbkr_3_r, rbkr_3_la, rbkr_3_mp, rbkr_3_bop, rbkr_3_tk, rbkr_3_fi, rbkr_3_k, rbkr_3_t, rbkr_4_v, rbkr_4_g, rbkr_4_pm, rbkr_4_pb, rbkr_4_pd, rbkr_4_pp, rbkr_4_o, rbkr_4_r, rbkr_4_la, rbkr_4_mp, rbkr_4_bop, rbkr_4_tk, rbkr_4_fi, rbkr_4_k, rbkr_4_t, rbkr_5_v, rbkr_5_g, rbkr_5_pm, rbkr_5_pb, rbkr_5_pd, rbkr_5_pp, rbkr_5_o, rbkr_5_r, rbkr_5_la, rbkr_5_mp, rbkr_5_bop, rbkr_5_tk, rbkr_5_fi, rbkr_5_k, rbkr_5_t, rbkr_6_v, rbkr_6_g, rbkr_6_pm, rbkr_6_pb, rbkr_6_pd, rbkr_6_pp, rbkr_6_o, rbkr_6_r, rbkr_6_la, rbkr_6_mp, rbkr_6_bop, rbkr_6_tk, rbkr_6_fi, rbkr_6_k, rbkr_6_t, rbkr_7_v, rbkr_7_g, rbkr_7_pm, rbkr_7_pb, rbkr_7_pd, rbkr_7_pp, rbkr_7_o, rbkr_7_r, rbkr_7_la, rbkr_7_mp, rbkr_7_bop, rbkr_7_tk, rbkr_7_fi, rbkr_7_k, rbkr_7_t, rbkr_8_v, rbkr_8_g, rbkr_8_pm, rbkr_8_pb, rbkr_8_pd, rbkr_8_pp, rbkr_8_o, rbkr_8_r, rbkr_8_la, rbkr_8_mp, rbkr_8_bop, rbkr_8_tk, rbkr_8_fi, rbkr_8_k, rbkr_8_t, diagnosis_klinik, gambaran_radiografis, indikasi, terapi, keterangan, prognosis_umum, prognosis_lokal, p1_tanggal, p1_indeksplak_ra_el16_b, p1_indeksplak_ra_el12_b, p1_indeksplak_ra_el11_b, p1_indeksplak_ra_el21_b, p1_indeksplak_ra_el22_b, p1_indeksplak_ra_el24_b, p1_indeksplak_ra_el26_b, p1_indeksplak_ra_el16_l, p1_indeksplak_ra_el12_l, p1_indeksplak_ra_el11_l, p1_indeksplak_ra_el21_l, p1_indeksplak_ra_el22_l, p1_indeksplak_ra_el24_l, p1_indeksplak_ra_el26_l, p1_indeksplak_rb_el36_b, p1_indeksplak_rb_el34_b, p1_indeksplak_rb_el32_b, p1_indeksplak_rb_el31_b, p1_indeksplak_rb_el41_b, p1_indeksplak_rb_el42_b, p1_indeksplak_rb_el46_b, p1_indeksplak_rb_el36_l, p1_indeksplak_rb_el34_l, p1_indeksplak_rb_el32_l, p1_indeksplak_rb_el31_l, p1_indeksplak_rb_el41_l, p1_indeksplak_rb_el42_l, p1_indeksplak_rb_el46_l, p1_bop_ra_el16_b, p1_bop_ra_el12_b, p1_bop_ra_el11_b, p1_bop_ra_el21_b, p1_bop_ra_el22_b, p1_bop_ra_el24_b, p1_bop_ra_el26_b, p1_bop_ra_el16_l, p1_bop_ra_el12_l, p1_bop_ra_el11_l, p1_bop_ra_el21_l, p1_bop_ra_el22_l, p1_bop_ra_el24_l, p1_bop_ra_el26_l, p1_bop_rb_el36_b, p1_bop_rb_el34_b, p1_bop_rb_el32_b, p1_bop_rb_el31_b, p1_bop_rb_el41_b, p1_bop_rb_el42_b, p1_bop_rb_el46_b, p1_bop_rb_el36_l, p1_bop_rb_el34_l, p1_bop_rb_el32_l, p1_bop_rb_el31_l, p1_bop_rb_el41_l, p1_bop_rb_el42_l, p1_bop_rb_el46_l, p1_indekskalkulus_ra_el16_b, p1_indekskalkulus_ra_el26_b, p1_indekskalkulus_ra_el16_l, p1_indekskalkulus_ra_el26_l, p1_indekskalkulus_rb_el36_b, p1_indekskalkulus_rb_el34_b, p1_indekskalkulus_rb_el32_b, p1_indekskalkulus_rb_el31_b, p1_indekskalkulus_rb_el41_b, p1_indekskalkulus_rb_el42_b, p1_indekskalkulus_rb_el46_b, p1_indekskalkulus_rb_el36_l, p1_indekskalkulus_rb_el34_l, p1_indekskalkulus_rb_el32_l, p1_indekskalkulus_rb_el31_l, p1_indekskalkulus_rb_el41_l, p1_indekskalkulus_rb_el42_l, p1_indekskalkulus_rb_el46_l, p2_tanggal, p2_indeksplak_ra_el16_b, p2_indeksplak_ra_el12_b, p2_indeksplak_ra_el11_b, p2_indeksplak_ra_el21_b, p2_indeksplak_ra_el22_b, p2_indeksplak_ra_el24_b, p2_indeksplak_ra_el26_b, p2_indeksplak_ra_el16_l, p2_indeksplak_ra_el12_l, p2_indeksplak_ra_el11_l, p2_indeksplak_ra_el21_l, p2_indeksplak_ra_el22_l, p2_indeksplak_ra_el24_l, p2_indeksplak_ra_el26_l, p2_indeksplak_rb_el36_b, p2_indeksplak_rb_el34_b, p2_indeksplak_rb_el32_b, p2_indeksplak_rb_el31_b, p2_indeksplak_rb_el41_b, p2_indeksplak_rb_el42_b, p2_indeksplak_rb_el46_b, p2_indeksplak_rb_el36_l, p2_indeksplak_rb_el34_l, p2_indeksplak_rb_el32_l, p2_indeksplak_rb_el31_l, p2_indeksplak_rb_el41_l, p2_indeksplak_rb_el42_l, p2_indeksplak_rb_el46_l, p2_bop_ra_el16_b, p2_bop_ra_el12_b, p2_bop_ra_el11_b, p2_bop_ra_el21_b, p2_bop_ra_el22_b, p2_bop_ra_el24_b, p2_bop_ra_el26_b, p2_bop_ra_el16_l, p2_bop_ra_el12_l, p2_bop_ra_el11_l, p2_bop_ra_el21_l, p2_bop_ra_el22_l, p2_bop_ra_el24_l, p2_bop_ra_el26_l, p2_bop_rb_el36_b, p2_bop_rb_el34_b, p2_bop_rb_el32_b, p2_bop_rb_el31_b, p2_bop_rb_el41_b, p2_bop_rb_el42_b, p2_bop_rb_el46_b, p2_bop_rb_el36_l, p2_bop_rb_el34_l, p2_bop_rb_el32_l, p2_bop_rb_el31_l, p2_bop_rb_el41_l, p2_bop_rb_el42_l, p2_bop_rb_el46_l, p2_indekskalkulus_ra_el16_b, p2_indekskalkulus_ra_el26_b, p2_indekskalkulus_ra_el16_l, p2_indekskalkulus_ra_el26_l, p2_indekskalkulus_rb_el36_b, p2_indekskalkulus_rb_el34_b, p2_indekskalkulus_rb_el32_b, p2_indekskalkulus_rb_el31_b, p2_indekskalkulus_rb_el41_b, p2_indekskalkulus_rb_el42_b, p2_indekskalkulus_rb_el46_b, p2_indekskalkulus_rb_el36_l, p2_indekskalkulus_rb_el34_l, p2_indekskalkulus_rb_el32_l, p2_indekskalkulus_rb_el31_l, p2_indekskalkulus_rb_el41_l, p2_indekskalkulus_rb_el42_l, p2_indekskalkulus_rb_el46_l, p3_tanggal, p3_indeksplak_ra_el16_b, p3_indeksplak_ra_el12_b, p3_indeksplak_ra_el11_b, p3_indeksplak_ra_el21_b, p3_indeksplak_ra_el22_b, p3_indeksplak_ra_el24_b, p3_indeksplak_ra_el26_b, p3_indeksplak_ra_el16_l, p3_indeksplak_ra_el12_l, p3_indeksplak_ra_el11_l, p3_indeksplak_ra_el21_l, p3_indeksplak_ra_el22_l, p3_indeksplak_ra_el24_l, p3_indeksplak_ra_el26_l, p3_indeksplak_rb_el36_b, p3_indeksplak_rb_el34_b, p3_indeksplak_rb_el32_b, p3_indeksplak_rb_el31_b, p3_indeksplak_rb_el41_b, p3_indeksplak_rb_el42_b, p3_indeksplak_rb_el46_b, p3_indeksplak_rb_el36_l, p3_indeksplak_rb_el34_l, p3_indeksplak_rb_el32_l, p3_indeksplak_rb_el31_l, p3_indeksplak_rb_el41_l, p3_indeksplak_rb_el42_l, p3_indeksplak_rb_el46_l, p3_bop_ra_el16_b, p3_bop_ra_el12_b, p3_bop_ra_el11_b, p3_bop_ra_el21_b, p3_bop_ra_el22_b, p3_bop_ra_el24_b, p3_bop_ra_el26_b, p3_bop_ra_el16_l, p3_bop_ra_el12_l, p3_bop_ra_el11_l, p3_bop_ra_el21_l, p3_bop_ra_el22_l, p3_bop_ra_el24_l, p3_bop_ra_el26_l, p3_bop_rb_el36_b, p3_bop_rb_el34_b, p3_bop_rb_el32_b, p3_bop_rb_el31_b, p3_bop_rb_el41_b, p3_bop_rb_el42_b, p3_bop_rb_el46_b, p3_bop_rb_el36_l, p3_bop_rb_el34_l, p3_bop_rb_el32_l, p3_bop_rb_el31_l, p3_bop_rb_el41_l, p3_bop_rb_el42_l, p3_bop_rb_el46_l, p3_indekskalkulus_ra_el16_b, p3_indekskalkulus_ra_el26_b, p3_indekskalkulus_ra_el16_l, p3_indekskalkulus_ra_el26_l, p3_indekskalkulus_rb_el36_b, p3_indekskalkulus_rb_el34_b, p3_indekskalkulus_rb_el32_b, p3_indekskalkulus_rb_el31_b, p3_indekskalkulus_rb_el41_b, p3_indekskalkulus_rb_el42_b, p3_indekskalkulus_rb_el46_b, p3_indekskalkulus_rb_el36_l, p3_indekskalkulus_rb_el34_l, p3_indekskalkulus_rb_el32_l, p3_indekskalkulus_rb_el31_l, p3_indekskalkulus_rb_el41_l, p3_indekskalkulus_rb_el42_l, p3_indekskalkulus_rb_el46_l, foto_klinis_oklusi_arah_kiri, foto_klinis_oklusi_arah_kanan, foto_klinis_oklusi_arah_anterior, foto_klinis_oklusal_rahang_atas, foto_klinis_oklusal_rahang_bawah, foto_klinis_before, foto_klinis_after, foto_ronsen_panoramik, terapi_s, terapi_o, terapi_a, terapi_p, terapi_ohis, terapi_bop, terapi_pm18, terapi_pm17, terapi_pm16, terapi_pm15, terapi_pm14, terapi_pm13, terapi_pm12, terapi_pm11, terapi_pm21, terapi_pm22, terapi_pm23, terapi_pm24, terapi_pm25, terapi_pm26, terapi_pm27, terapi_pm28, terapi_pm38, terapi_pm37, terapi_pm36, terapi_pm35, terapi_pm34, terapi_pm33, terapi_pm32, terapi_pm31, terapi_pm41, terapi_pm42, terapi_pm43, terapi_pm44, terapi_pm45, terapi_pm46, terapi_pm47, terapi_pm48, terapi_pb18, terapi_pb17, terapi_pb16, terapi_pb15, terapi_pb14, terapi_pb13, terapi_pb12, terapi_pb11, terapi_pb21, terapi_pb22, terapi_pb23, terapi_pb24, terapi_pb25, terapi_pb26, terapi_pb27, terapi_pb28, terapi_pb38, terapi_pb37, terapi_pb36, terapi_pb35, terapi_pb34, terapi_pb33, terapi_pb32, terapi_pb31, terapi_pb41, terapi_pb42, terapi_pb43, terapi_pb44, terapi_pb45, terapi_pb46, terapi_pb47, terapi_pb48, terapi_pd18, terapi_pd17, terapi_pd16, terapi_pd15, terapi_pd14, terapi_pd13, terapi_pd12, terapi_pd11, terapi_pd21, terapi_pd22, terapi_pd23, terapi_pd24, terapi_pd25, terapi_pd26, terapi_pd27, terapi_pd28, terapi_pd38, terapi_pd37, terapi_pd36, terapi_pd35, terapi_pd34, terapi_pd33, terapi_pd32, terapi_pd31, terapi_pd41, terapi_pd42, terapi_pd43, terapi_pd44, terapi_pd45, terapi_pd46, terapi_pd47, terapi_pd48, terapi_pl18, terapi_pl17, terapi_pl16, terapi_pl15, terapi_pl14, terapi_pl13, terapi_pl12, terapi_pl11, terapi_pl21, terapi_pl22, terapi_pl23, terapi_pl24, terapi_pl25, terapi_pl26, terapi_pl27, terapi_pl28, terapi_pl38, terapi_pl37, terapi_pl36, terapi_pl35, terapi_pl34, terapi_pl33, terapi_pl32, terapi_pl31, terapi_pl41, terapi_pl42, terapi_pl43, terapi_pl44, terapi_pl45, terapi_pl46, terapi_pl47, terapi_pl48, created_at, updated_at, status_emr, status_penilaian) FROM stdin;
4fab2da9-539c-4dd9-8ab2-dc7f989d0dac	Sekar Decita Ananda Iswanti	4122023044	2024-03-07 00:00:00	\N	RJJP070524-0299	OP078954-070524-0164	07-89-54	\N	2024-05-07 08:57:51	SMU	NAFISAH AMALIA, NY	23	F	JL. KALIBARU BARAT VII	08998342254	\N	\N	\N	\N	\N	drg. Yulia Rachma wijayanti, Sp.Perio,MM	Ada karang gigi dan mudah berdarah saat sikat gigi	Pasien wanita berusia 22 tahun datang ke RS yarsi dengan keluhan gigi depan bawah terasa kasar karena karang gigi dan gusi mudah berdarah saat sikat gigi.	Yes	\N	Tidak	\N	\N	Tidak	\N	Pernah	4 batang/hari	2020-06-23 00:00:00	2024-04-18 00:00:00	Tidak	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
d994f9b6-760f-416c-a67f-eb84a816a1b5	Jihan Ar Rohim	4122023035	2024-02-19 00:00:00	\N	RJJP060524-0256	OP078805-060524-0036	07-88-05	\N	2024-05-06 09:04:28	SMU	INDRA SYAPUTRA, TN	26	M	JL YUNUS NO.51-C	081290887941	\N	\N	\N	\N	\N	drg. Yulia Rachma wijayanti, Sp.Perio,MM	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Tidak ada kelainan	120/68	Tidak ada kelainan	21(D2,3,1), 36 (D3,1,1)	0,07	0,53	1,2	1,73	Sedang	\N	+	\N	\N	\N	\N	+	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	-	-	Fase 1 (Non bedah)\n-SRP\n-DHE\n-Penambalan pada gigi 21,36,37, 46, 47\nFase IV (Pemeliharaan) \n-Pemeliharaan kesehatan jaringan periodontal\n-Kontrol 1 minggu setelah perawatan	-	Sedang, pasien berusia 26 tahun, tidak memiliki penyakit Sistemik, merokok, Pasien kooperatif.	Sedang, skor OHIS Sedang dengan plak dan kalkulus yang cukup banyak pada daerah lingual RB dengan skor 3 , tidak terdapat kegoyangan pada gigi.	\N	2	0	0	0	0	1	2	1	0	0	2	0	2	1	0	0	0	0	0	0	1	1	1	0	0	0	0	1	0	0	0	0	0	0	1	0	0	0	0	0	0	0	0	0	0	0	1	0	0	0	0	0	0	0	0	0	1	\N	0	\N	0	0	1	1	1	1	0	2	2	3	3	3	3	0	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/periodonti/fotoklinisintraoral/6fd47fff-202f-4782-8a3b-32683e59a338.HEIC	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-05-27 06:25:36	WRITE	\N
41911ff0-c9f4-4fc8-aeac-9a4fc4756245	Sekar Decita Ananda Iswanti	4122023044	2024-03-07 00:00:00	\N	RJJP230424-0402	OP076046-230424-0055	07-60-46	\N	2024-04-23 11:13:26	Aktif S1	LARAS FAJRI NANDA WIDIISWA, NN	22	F	JL Y NO 21 A	081318392492	\N	\N	\N	\N	\N	drg. Yulia Rachma wijayanti, Sp.Perio,MM	Ada karang gigi dan gusi turun	Pasien perempuan berusia 22 tahun datang ke RS yarsi dengan keluhan gigi belakang bawah terasa kasar karena karang gigi dan gusi turun pada gigi bawah depan kanan dan kiri.	No	\N	Tidak	\N	\N	Tidak	\N	Tidak Pernah	\N	\N	\N	Tidak	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2	2	2	2	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	2	1	2	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	3	0	2	0	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	2	2	2	0	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	3	1	2	1	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	0	2	1	2	\N	\N	\N	\N	+	\N	\N	+	\N	\N	\N	1	1	2	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4	0	3	2	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	3	0	2	0	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	2	2	3	0	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	2	2	2	2	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	3	1	2	2	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	3	3	1	2	\N	\N	\N	\N	+	\N	\N	+	\N	\N	\N	3	1	1	3	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	1	2	0	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	2	2	2	0	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	2	1	3	1	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	4	2	2	2	\N	\N	\N	\N	+	\N	\N	+	\N	\N	\N	4	2	2	2	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	2	1	2	2	\N	\N	\N	\N	+	\N	\N	+	\N	\N	\N	1	2	2	2	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2	2	2	0	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	2	2	2	1	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	1	2	1	2	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	2	2	2	2	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	2	2	1	2	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	2	1	2	2	\N	\N	\N	\N	\N	\N	\N	+	\N	\N	\N	3	2	2	1	\N	\N	\N	\N	+	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
25ad369e-13ee-47ad-81d5-dc70121e10e1	Sekar Decita Ananda Iswanti	4122023044	2024-03-07 00:00:00	\N	RJJP080524-0649	OP076046-080524-0128	07-60-46	\N	2024-05-08 15:31:01	Aktif S1	LARAS FAJRI NANDA WIDIISWA, NN	22	F	JL Y NO 21 A	081318392492	\N	\N	\N	\N	\N	drg. Yulia Rachma wijayanti, Sp.Perio,MM	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2024-04-29 00:00:00	2	1	2	1	2	1	2	0	1	1	1	1	2	2	1	1	1	1	1	1	1	2	2	1	1	1	1	2	2	0	1	1	1	2	1	1	0	0	0	0	0	1	1	1	2	2	1	1	0	2	0	0	0	0	0	0	2	\N	1	\N	1	1	0	0	0	0	1	2	0	0	0	0	0	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/periodonti/fotoklinisintraoral/48fd0014-b454-4722-984b-8c757f8b5291.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/periodonti/fotoklinisintraoral/af0febb6-dd13-496e-83a6-589e69c615a4.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/periodonti/fotoklinisintraoral/8cc32337-d36d-423b-9de9-bcc2618e8953.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/periodonti/fotoklinisintraoral/f6ecf5d1-2ff9-41c8-a0f6-a3a3478834a4.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/periodonti/fotoklinisintraoral/c7ba66e8-2ba8-4e18-8f6e-e6ea0bfa91a4.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/periodonti/fotoklinisintraoral/6051d1ad-6d6a-47e6-b8b6-0e5d96f2782e.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/periodonti/fotoklinisintraoral/6a47703e-3716-4e96-9f27-cb2c01a3f587.jpg	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/periodonti/fotopanoramik/849c63c6-470a-49aa-a3c9-c90b451c7293.jpg	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
09a1bc40-ca93-4c56-8ba3-8b4da1766b9d	Sahri Muhamad Risky	4122023043	2024-02-19 00:00:00	\N	RJJP080524-0444	OP079094-080524-0084	07-90-94	\N	2024-05-08 11:14:45	SMU	AGHIEL DZAKWAMUFID SUMUAL, TN	23	M	JL. UTAN PANJANG III NO. 4	08978133476	\N	\N	\N	\N	\N	drg. Yulia Rachma wijayanti, Sp.Perio,MM	terdapat gigi yang memiliki karang gigi	pasien laki laki berusia 22 tahun datang ke rsu yarsi dengan keluhan gigi terdapat permukaan kasardan berdarah	Yes	\N	Tidak	\N	\N	Tidak	\N	Ya, Aktif	2	\N	\N	Tidak	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
6a9b75cf-f131-4ed5-9e5f-d3e1047e0792	\N	4122023036	\N	\N	RJJP230424-0406	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
019802a3-cf80-404f-8a36-1e0cebbacb1f	\N	4122023043	\N	\N	RJJP150524-0450	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5f25f585-8d01-41c0-8a6d-c2b2bad493e8	Sekar Decita Ananda Iswanti	4122023044	2024-03-07 00:00:00	\N	RJJP130524-0436	OP076046-080524-0128	07-60-46	\N	2024-05-13 11:21:20	Aktif S1	LARAS FAJRI NANDA WIDIISWA, NN	22	F	JL Y NO 21 A	081318392492	\N	\N	\N	\N	\N	drg. Yulia Rachma wijayanti, Sp.Perio,MM	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	3	3	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	3	3	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	3	3	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	3	33	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	3	3	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	\N
bc43ab82-eb8a-481d-ba10-604da0a977e3	\N	4122023044	\N	\N	RJJP080524-0336	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
036ba64a-b471-4759-864c-48ed62c244af	\N	4122023044	\N	\N	RJJP280524-0480	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
aacb5098-0bcc-4f36-8eed-fb447e38f8cf	\N	4122023034	\N	\N	RJJP290524-0493	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
bdd753d8-4e17-418d-a5aa-afc56fe91662	\N	4122023032	\N	\N	RJJP300524-0354	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- TOC entry 3719 (class 0 OID 16491)
-- Dependencies: 227
-- Data for Name: emrprostodontie_logbooks; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.emrprostodontie_logbooks (id, dateentri, work, usernameentry, usernameentryname, lectureid, lecturename, updated_at, created_at, emrid, dateverifylecture) FROM stdin;
\.


--
-- TOC entry 3720 (class 0 OID 16496)
-- Dependencies: 228
-- Data for Name: emrprostodonties; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.emrprostodonties (id, noregister, noepisode, nomorrekammedik, tanggal, namapasien, pekerjaan, jeniskelamin, alamatpasien, namaoperator, nomortelpon, npm, keluhanutama, riwayatgeligi, pengalamandengangigitiruan, estetis, fungsibicara, penguyahan, pembiayaan, lainlain, wajah, profilmuka, pupil, tragus, hidung, pernafasanmelaluihidung, bibiratas, bibiratas_b, bibirbawah, bibirbawah_b, submandibulariskanan, submandibulariskanan_b, submandibulariskiri, submandibulariskiri_b, sublingualis, sublingualis_b, sisikiri, sisikirisejak, sisikanan, sisikanansejak, membukamulut, membukamulut_b, kelainanlain, higienemulut, salivakuantitas, salivakonsisten, lidahukuran, lidahposisiwright, lidahmobilitas, refleksmuntah, mukosamulut, mukosamulutberupa, gigitan, gigitanbilaada, gigitanterbuka, gigitanterbukaregion, gigitansilang, gigitansilangregion, hubunganrahang, pemeriksaanrontgendental, elemengigi, pemeriksaanrontgenpanoramik, pemeriksaanrontgentmj, frakturgigi, frakturarah, frakturbesar, intraorallainlain, perbandinganmahkotadanakargigi, interprestasifotorontgen, intraoralkebiasaanburuk, intraoralkebiasaanburukberupa, pemeriksaanodontogram_11_51, pemeriksaanodontogram_12_52, pemeriksaanodontogram_13_53, pemeriksaanodontogram_14_54, pemeriksaanodontogram_15_55, pemeriksaanodontogram_16, pemeriksaanodontogram_17, pemeriksaanodontogram_18, pemeriksaanodontogram_61_21, pemeriksaanodontogram_62_22, pemeriksaanodontogram_63_23, pemeriksaanodontogram_64_24, pemeriksaanodontogram_65_25, pemeriksaanodontogram_26, pemeriksaanodontogram_27, pemeriksaanodontogram_28, pemeriksaanodontogram_48, pemeriksaanodontogram_47, pemeriksaanodontogram_46, pemeriksaanodontogram_45_85, pemeriksaanodontogram_44_84, pemeriksaanodontogram_43_83, pemeriksaanodontogram_42_82, pemeriksaanodontogram_41_81, pemeriksaanodontogram_38, pemeriksaanodontogram_37, pemeriksaanodontogram_36, pemeriksaanodontogram_75_35, pemeriksaanodontogram_74_34, pemeriksaanodontogram_73_33, pemeriksaanodontogram_72_32, pemeriksaanodontogram_71_31, rahangataspostkiri, rahangataspostkanan, rahangatasanterior, rahangbawahpostkiri, rahangbawahpostkanan, rahangbawahanterior, rahangatasbentukpostkiri, rahangatasbentukpostkanan, rahangatasbentukanterior, rahangatasketinggianpostkiri, rahangatasketinggianpostkanan, rahangatasketinggiananterior, rahangatastahananjaringanpostkiri, rahangatastahananjaringanpostkanan, rahangatastahananjaringananterior, rahangatasbentukpermukaanpostkiri, rahangatasbentukpermukaanpostkanan, rahangatasbentukpermukaananterior, rahangbawahbentukpostkiri, rahangbawahbentukpostkanan, rahangbawahbentukanterior, rahangbawahketinggianpostkiri, rahangbawahketinggianpostkanan, rahangbawahketinggiananterior, rahangbawahtahananjaringanpostkiri, rahangbawahtahananjaringanpostkanan, rahangbawahtahananjaringananterior, rahangbawahbentukpermukaanpostkiri, rahangbawahbentukpermukaanpostkanan, rahangbawahbentukpermukaananterior, anterior, prosteriorkiri, prosteriorkanan, labialissuperior, labialisinferior, bukalisrahangataskiri, bukalisrahangataskanan, bukalisrahangbawahkiri, bukalisrahangbawahkanan, lingualis, palatum, kedalaman, toruspalatinus, palatummolle, tuberorositasalveolariskiri, tuberorositasalveolariskanan, ruangretromilahioidkiri, ruangretromilahioidkanan, bentuklengkungrahangatas, bentuklengkungrahangbawah, perlekatandasarmulut, pemeriksaanlain_lainlain, sikapmental, diagnosa, rahangatas, rahangataselemen, rahangbawah, rahangbawahelemen, gigitiruancekat, gigitiruancekatelemen, perawatanperiodontal, perawatanbedah, perawatanbedah_ada, perawatanbedahelemen, perawatanbedahlainlain, konservasigigi, konservasigigielemen, rekonturing, adapembuatanmahkota, pengasahangigimiring, pengasahangigiextruded, rekonturinglainlain, macamcetakan_ra, acamcetakan_rb, warnagigi, klasifikasidaerahtidakbergigirahangatas, klasifikasidaerahtidakbergigirahangbawah, gigipenyangga, direk, indirek, platdasar, anasirgigi, prognosis, prognosisalasan, reliningregio, reliningregiotanggal, reparasiregio, reparasiregiotanggal, perawatanulangsebab, perawatanulanglainlain, perawatanulanglainlaintanggal, perawatanulangketerangan, created_at, updated_at, nim, designngigi, designngigitext, fotoodontogram, status_emr, status_penilaian) FROM stdin;
9fc1eb88-63ed-40a6-9561-0c285c8af526	RJJP080524-0653	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023034	\N	\N	\N	\N	\N
\.


--
-- TOC entry 3721 (class 0 OID 16501)
-- Dependencies: 229
-- Data for Name: emrradiologies; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.emrradiologies (id, noepisode, noregistrasi, nomr, namapasien, alamat, usia, tglpotret, diagnosaklinik, foto, jenisradiologi, periaprikal_int_mahkota, periaprikal_int_akar, periaprikal_int_membran, periaprikal_int_lamina_dura, periaprikal_int_furkasi, periaprikal_int_alveoral, periaprikal_int_kondisi_periaprikal, periaprikal_int_kesan, periaprikal_int_lesigigi, periaprikal_int_suspek, nim, namaoperator, namadokter, panoramik_miising_teeth, panoramik_missing_agnesia, panoramik_persistensi, panoramik_impaki, panoramik_kondisi_mahkota, panoramik_kondisi_akar, panoramik_kondisi_alveoral, panoramik_kondisi_periaprikal, panoramik_area_dua, oklusal_kesan, oklusal_suspek_radiognosis, status_emr, status_penilaian, jenis_radiologi, url) FROM stdin;
cd8d55d3-22b1-4bb1-86c8-f82c3915d90d	-	RKG080524-6876	-	Periapikal 1	-	0	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023042	\N	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PERIAPIKAL	\N
7cc7438c-eac0-4a4a-b188-cec3b308aef1	-	RKG270524-2501	-	Panoramik	Cempaka putih	19	2024-05-27	Odontogenic keratocyst	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/14ff8805-c35d-4fcc-ba48-5669c58f7542.png	PANORAMIK	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023032	Ivan Hasan	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	Dalam batas normal	Dalam batas normal	Tidak ada persistensi	Dalam batas normal	Terdapat gambaran radiopak pada gigi 36	Terdapat gambaran radiopak pada gigi 36	Dalam batas normal	Terdapat gambaran radiolusen berbatas jelas dan tegas pada angulus mandibula	Dalam batas normal	\N	\N	WRITE	OPEN	PANORAMIK	\N
b5c774be-cc76-4ef4-b416-8055993aa6c8	-	RKG160524-3183	-	Periapikal 1	-	0	\N	hbi	\N	PERIAPIKAL	'hib	bhi'IHB	bhi'	b'hi	'bhiobh	O"BH"	bhioBHI"	'obhi'	'bhi	'bhi	4122023042	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	WRITE	PERIAPIKAL	\N
2c997aa8-5fea-4acd-a6d7-7c3818273e0b	-	RKG080524-2232	-	periapikal 1	-	0	\N	Pulp Stone	\N	PERIAPIKAL	DBN	Akar tunggal dan lurus terdapat gambaran radiopak pada bagian 2/3 dari apeks, akar terbuka	Melebar	DBN	-	DBN	-	Kelainan pada akar, membran periodontal	-	Pulp Stone\nDD : Dens Invaginatus \nDD 2 : Sklerosis Pulpa	4122023045	Shabrina Ghisani M	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
5b100b93-34f2-4931-9862-f124c2bc9c22	-	RKG080524-5991	-	-	Jl. X	0	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023039	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PERIAPIKAL	\N
aa3d14b8-9a43-4fb6-8690-8120576ac1e8	-	RKG080524-2580	-	periapikal 1	-	0	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023024	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PERIAPIKAL	\N
9d0870bf-8a0a-47eb-b4e6-5848137e0a03	-	RKG080524-7420	-	Periapikal 2	-	0	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023024	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PERIAPIKAL	\N
e9326f2e-f78e-42bb-8ab0-579594cb4074	-	RKG080524-3144	-	Ny.X	Jalan. Y	0	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023037	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PERIAPIKAL	\N
4232b6ed-ffc7-42fe-bd5e-cf8b02679054	-	RKG080524-8580	-	Periapikal 1	cempaka putih	0	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023025	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PERIAPIKAL	\N
4a1703fd-e925-4bb7-a592-e1451f6f9bbe	-	RKG080524-3208	-	Periapikal 1	-	0	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Breaniza Dhari	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PERIAPIKAL	\N
69e07368-6378-49b5-a83f-cb156e07acdf	-	RKG080524-7020	-	Periapikal 1	-	0	2024-05-08	Abses Periapikal	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/08a88267-4d02-412e-95d2-a4eaeda0ea84.png	PERIAPIKAL	terdapat gambaran radiopak pada mahkota gigi	terdapat gambaran radiopak pada saluran akar	membran periodontal distal = 1/3 servikal : dalam batas normal, 1/3 tengah : mengihlang. 1/3 apikal : menghilang\n\nmembran periodontal mesial = 1/3 servikal : dalam batas normal, 1/3 tengah : mengihlang. 1/3 apikal : menghilang	lamina dura distal = 1/3 servikal : dalam batas normal, 1/3 tengah : menghilang, 1/3 apikal : menghilang\n\nlamina dura mesial = 1/3 servikal : dalam batas normal, 1/3 tengah : menghilang, 1/3 apikal : menghilang	tidak terdapat furkasi	dalam batas normal	terdapat gambaran radiolusen berbatas tidak jelas dan tidak tegas pada gigi 25 dari 1/3 setengah akar sampai 1/3 apikal akar	terdapat kelainan pada mahkota, akar, lamina dura, membran periodontal, periapikal	-	abses periapikal	4122023032	Ivan Hasan	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	WRITE	PERIAPIKAL	\N
2d1bc362-11fd-4553-90af-ecafa357c7a3	02	RKG280524-9029	RKG 2	Rivan	Jl. Cemara III No. 7	0	2024-05-28	Cementoblastoma	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/333b2c67-c28d-40f7-be0e-0bd1d90acc73.jpeg	PERIAPIKAL	DBN	Terdapat 2 akar dan 2 saluran akar	terputus pada akar distal di 1/3 apikal	Terputus pada akar distal di 1/3 apikal, terputus pada akar mesial di 1/3 apikal	DBN	DBN	Terdapat gambaran radiolusen dan radiopak. Radiopak pada lesi dan dikelilingi gambaran radiolusen	Terdapat kelainan pada akar, membran periodontal, dan lamina dura	Site : periapikal akar distal\nSize: -+ 2 cm\nShape : Reguler\nSymetri : Simetris\nJumlah : 1\nBorder : Berbatas jelas dan tegas\nContent : lesi radiolusen berbatas tegas\nAssociation : laminadura terputus, membran periodontal menghilang pada akar distal	Cementoblastoma \nDD : hypercementosis, Densbond Island	4122023045	Shabrina Ghisani	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	FINISH	OPEN	PERIAPIKAL	\N
8f4ebd52-576b-46a8-992a-d2201c399794	04	RKG270524-8126	rkg 2	Ny.X/ Periapikal Intepretasi rkg 2	Jakarta	46	2024-05-27	Dilaserasi adalah pembengkokan abnormal pada akar atau mahkota gigi.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/02ef69c4-5632-43d6-8a06-29a1520dc746.png	PERIAPIKAL	Terdapat gambaran radiolusen pada bagian mahkota gigi 46 hingga kamar pulpa bagian distal	Akar berjumlah 2, 2 saluran akar	terputus di 1/3 apikal	menghilang pada 1/3 apikal	terdapat furkasi	dalam batas normal	lamina dura menebal pada 1/3 apikal, dan membran periodontal terputus di 1/3 apikal	terdapat kelainan pada lamina dura menebal pada 1/3 apikal, dan membran periodontal terputus di 1/3 apikal	-	dilaserasi akar \ndd: fusi, dense bond island	4122023025	Amalia Rafa Wulandari	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
c551cbe8-df68-4268-85c2-a14a1074f51e	01	RKG270524-2493	RKG 1	Ny. X	Korea	0	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023024	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
cfb0ab56-34e4-4ee4-baf8-049e82e7c696	-	RKG250524-2562	-	Periapikal 1	Cempaka Putih	21	2024-05-25	Odontogenic Myxoma	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/9d6c90cc-cdf8-434b-8633-c055564e30fd.png	PERIAPIKAL	Terdapat gambaran radiopak pada gigi 26 oklusal dari email hingga kamar pulpa	Dalam batas normal	Menghilang pada apikal akar	Terputus pada 1/3 apikal akar distal gigi 25	Tidak ada furkasi	Adanya penurunan tulang alveolar crest gigi 25 pada mesial secara vertikal	Terdapat gambaran radiolusen berbatas jelas dan tegas dari 1/3 apikal akar distal gigi 25 hingga mesial gigi 26	Terdapat kelainan pada mahkota, membran periodontal, lamina dura, alveolar crest, dan periapikal	Site : Lateral inferior berbatasan dengan gigi 24 dan 25\nSize : kurang lebih 4,5 cm\nShape : irreguler\nSymetri : asimetris\nJumlah : 1\nBorder : Berbatas jelas dan tegas\nContent : Lesi radiolusen dikelilingi batas radiopak	Miksoma adalah tumor jinak yang langka, yang mungkin melibatkan jaringan keras dan lunak. Jika melibatkan jaringan tulang, maka akan mempengaruhi tulang wajah. ditandai dengan jaringan putih keabu-abuan yang bersifat mukoid atau agar-agar yang menggantikan tulang cancellous dan memperluas korteks\n\nDiagnosis banding : Ameloblastoma dan Keratocyst\nPerbedaan :\nMyxoma : tumbuh lambat, jarang terjadi pada usia dibawah 10 tahun dan diatas 50 tahun. bersifat lokal agresif, biasa terjadi pada gigi P (premolar) dan M (molar), jarang terjadi pada ramus dan kondilus.\n\nAmeloblastoma : tumor jinak epitelial odontogenik yang berasal dari jaringan pembentuk gigi yaitu jaringan pembentuk email gigi yang mengalami gangguan perubahan pada saat proses pembentukan gigi.\n\nKeratocyst : kista yang berasal dari gigi (primordial odontogenic epithelium) dan memiliki lapisan keratin serta mempunyai gejala klinis yang agresif yaitu mempunyai tingkat rekuren yang tinggi.\n\nPersamaan :\nMyxoma : tumbuh lambat, lesi radiolusen berbatas jelas dan tegas. dapat menggeser gigi\n\nAmeloblastoma : tumbuh lambat, memiliki batas yang jelas dan tegas. dapat menggeser gigi dan resorpsi akar yang luas\n\nKeratocyst : tumbuh lambat, memiliki batas jelas dan tegas. lesi radiolusen. muncul di mandibula, dapat menggeser gigi	4122023032	Ivan Hasan	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
b8d27e17-5f9f-482d-910a-4ffcbe81a460	3	RKG280524-9586	3	RKG 1 : Periapikal 3 : Tn. C	Jl. C	22	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023039	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PERIAPIKAL	\N
b983a9d8-67a0-4bb7-ad8e-7d0f40c47a34	-	RKG250524-1898	-	Periapikal 1	Cempaka putih	62	2024-05-25	Abses periapikal	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/444b2330-74d2-4431-95a1-bd451217a47b.png	PERIAPIKAL	Terdapat gambaran radiopak pada mahkota gigi 25 dari email sampai pulpa	akar : akar 1\nkamar pulpa : terdapat gambaran radiopak pada kamar pulpa\nsaluran akar : terdapat gambaran radiopak saluran akar	mesial\n1/3 servikal : dalam batas normal\n1/3 tengah : menghilang\n1/3 apikal : menghilang\n\ndistal\n1/3 servikal : dalam batas normal\n1/3 tengah : menghilang\n1/3 apikal : menghilang	mesial\n1/3 servikal : dalam batas normal\n1/3 tengah : menghilang\n1/3 apikal : menghilang\n\ndistal\n1/3 servikal : dalam batas normal\n1/3 tengah : menghilang\n1/3 apikal : menghilang	tidak ada	tinggi\nmesial : dalam batas normal, distal : dalam batas normal\nbentuk\nmesial : irreguler, distal irreguler\ntulang kortikal : tidak ada\nkontinuitas : tidak ada\noutline : tidak ada\ntebal/lebar : tidak ada\ndensitas : tidak ada\ntulang kanselus (spongious)\ndensitas : padat\npola : bulat	radiodensitas lesi : radiolusen berbatas jelas dan tidak tegas\nlokasi dan perluasan lesi : 1/3 tengah akar gigi 25 meluas ke apikar akar\nbentuk dan ukuran diameter lesi : 0,98 mm\nbatas tepi : jelas dan tidak tegas\nstruktur interna lesi : radiolusen\nefek lesi terhadap jaringan sekitar : tidak ada	tinggi tulang yang ada : tidak ada\nkondisi alveolar crest : tidak ada\nruang periodontal dan lamina dura : menghilang 1/3 tengah akar\nrasio mahkota akar : 01:02	radiodensitas bahan restorasi : tidak ada\nkontur restorasi : over/undercontour : tidak ada\nkonsisi titik kontak : tidak ada\nadaptasi bahan tumpatan dengan basis tumpatan : tidak ada\nimarginal fit pada restorasi indirect : tidak ada	Diagnosis banding :\nGranuloma abses\nKista periapikal	4122023032	Ivan Hasan	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
582395bb-99e6-47de-911a-64be991bf4aa	-	RKG250524-2836	-	Oklusal	Cempaka Putih	31	2024-05-25	Kista Radikuler	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/e91f259b-d5fc-4312-8b60-8d4e13b0815d.png	OKLUSI	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023032	Ivan Hasan	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	Site : Terdapat gambaran radiolusen lateral superior berbatasan dengan gigi 22 dengan 21 sampai fossa nasal posterior dan gambaran radiolusen lateral superior berbatasan dengan gigi 11 dengan 12 sampai fossa nasal posterior\nSize : kurang lebih 5 cm - 3,5 cm\nShape : irreguler\nSymetri : asimetri\nJumlah : 2\nBorder : Berbatas jelas dan tegas\nContent : lesi radiolusen berbatas jelas	Diagnosis banding : Foramen insisivus dan Kista duktusnasopalatinus\n\nPerbedaan\nKista radikular : perpindahan dan resorpsi ekternal  akar gigi berdekatan jika lesi besar. ukuran >6 mm. hilangnya lamina dura.\n\nForamen insisivus : menyebabkan perpindahan akar gigi, ukuran <6 mm. Lamina dura utuh disekitar gigi 11 dan 21. \n\nKista duktus nasopalatina : perpindahan gigi berdekatan kearah distal. di antara apikal akar gigi 11 dan 21  berhubungan dengan karies luas / restorasi dalam. ukuran >6 mm. Lamina dura utuh disekitar gigi 11 dan 21. \n\nPersamaan\nKista radikular : perpindahan dan resorpsi ekternal akar gigi berdekatan jika lesi besar. Radiolusen di apeks gigi insisivus sentral RA, berbatas jelas, berbentuk bulat, Khas lokasi dekat midline anterior RA.\n\nForamen insisivus : menyebabkan perpindahan akar gigi, radiolusen di antara akar, di daerah 1/3 apikal-tengah akar gigi 11 dan 21. berbatas jelas, berbentuk bulat. Khas lokasi dekat midline anterior RA.\n\nKista duktus nasopalatina : perpindahan gigi berdekatan kearah distal. Radiolusen di apeks gigi insisivus sentral RA, berbatas jelas, berbentuk bulat. Khas lokasi dekat midline anterior RA.	WRITE	OPEN	OKLUSI	\N
5fcdf549-caa4-4924-a2a9-0542b5c50635	-	RKG250524-1348	-	Periapikal 2	Cempaka putih	6	2024-05-25	Fusi pada gigi 81 82	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/454e3e7e-925d-493c-a256-e00a5214c4e0.png	PERIAPIKAL	Dalam batas normal	akar : akar 2\nkamar pulpa : dalam batas normal\nsaluran akar : dalam batas normal	mesial\n1/3 servikal : menghilang\n1/3 tengah : dalam batas normal\n1/3 apikal : dalam batas normal\n\ndistal\n1/3 servikal : menghilang\n1/3 tengah : dalam batas normal\n1/3 apikal : dalam batas normal	mesial\n1/3 servikal : menghilang\n1/3 tengah : dalam batas normal\n1/3 apikal : dalam batas normal\n\ndistal\n1/3 servikal : menghilang\n1/3 tengah : dalam batas normal\n1/3 apikal : dalam batas normal	tidak ada	tinggi\nmesial : 0,34 mm, distal : 0,34 mm\nbentuk\nmesial : vertikal, distal : vertikal\ntulang kortikal : tidak ada\nkontinuitas : tidak ada\noutline : tidak ada\ntebal/lebar : tidak ada\ndensitas : tidak ada\ntulang kanselus (spongious)\ndensitas : padat\npola : bulat	radiodensitas lesi : tidak ada\nlokasi dan perluasan lesi : tidak ada\nbentuk dan ukuran diameter lesi : tidak ada\nbatas tepi : tidak ada\nstruktur interna lesi : tidak ada\nefek lesi terhadap jaringan sekitar : tidak ada	tinggi tulang yang ada : tidak ada\nkondisi alveolar crest : terdapat penurunan tulang alveolar crest secara vertikal\nruang periodontal dan lamina dura : menghilang 1/3 servikal akar\nrasio mahkota akar : 01:02	radiodensitas bahan restorasi : tidak ada\nkontur restorasi : over/undercontour : tidak ada\nkonsisi titik kontak : tidak ada\nadaptasi bahan tumpatan dengan basis tumpatan : tidak ada\nimarginal fit pada restorasi indirect : tidak ada	Gemination\nMakrodonsia	4122023032	Ivan Hasan	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
43324e57-4c9d-4ceb-9427-09e7e585d177	-	RKG260524-2448	-	Periapikal 4	-	14	2024-05-26	Dense bone island	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/deaecb8c-4e4e-4017-900d-0172986a1011.png	PERIAPIKAL	tidak dapat di evaluasi karena terdapat gambaran radiopak ortodonti cekat	akar : akar 1\nkamar pulpa : dalam batas normal\nsaluran akar : dalam batas normal	mesial\n1/3 servikal : dalam batas normal\n1/3 tengah : dalam batas normal\n1/3 apikal : dalam batas normal\n\ndistal\n1/3 servikal : dalam batas normal\n1/3 tengah : terputus\n1/3 apikal : terputus	mesial\n1/3 servikal : dalam batas normal\n1/3 tengah : dalam batas normal\n1/3 apikal : dalam batas normal\n\ndistal\n1/3 servikal : dalam batas normal\n1/3 tengah : terputus\n1/3 apikal : terputus	Tidak ada	tinggi\nmesial : 0,11 mm, distal : dalam batas normal\nbentuk\nmesial : horizontal, distal : irreguler\ntulang kortikal : tidak ada\nkontinuitas : tidak ada\noutline : tidak ada\ntebal/lebar : tidak ada\ndensitas : tidak ada\ntulang kanselus (spongious)\ndensitas : padat\npola : bulat	radiodensitas lesi : radiopak berbatas jelas dan tegas\nlokasi dan perluasan lesi : lateral inferior berbatas dengan gigi 35 dan 36\nbentuk dan ukuran diameter lesi : 0,76 mm\nbatas tepi : jelas dan tegas\nstruktur interna lesi : radiopak\nefek lesi terhadap jaringan sekitar : tidak ada	tinggi tulang yang ada : tidak ada\nkondisi alveolar crest : terdapat penurunan tulang alveolar crest secara horizontal\nruang periodontal dan lamina dura : menghilang 1/3 tengah akar\nrasio mahkota akar : 01:02	radiodensitas bahan restorasi : tidak ada\nkontur restorasi : over/undercontour : tidak ada\nkonsisi titik kontak : tidak ada\nadaptasi bahan tumpatan dengan basis tumpatan : tidak ada\nimarginal fit pada restorasi indirect : tidak ada	Granuloma abses\nKista periapikal	4122023032	Ivan Hasan	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
eedf62c1-0f76-4e4c-a27c-0837c52da12d	-	RKG260524-9458	-	Periapikal 3	Cempaka putih	30	2024-05-26	Kista radikuler	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/99095ee6-0f17-4d52-a992-80e363aecb40.png	PERIAPIKAL	terdapat gambaran radiopak dari email sampai pulpa	akar : akar 1\nkamar pulpa : terdapat gambaran radiopak pada kamar pulpa\nsaluran akar : terdapat gambaran radiopak saluran akar	mesial\n1/3 servikal : menghilang\n1/3 tengah : dalam batas normal\n1/3 apikal : menghilang\n\ndistal\n1/3 servikal : menghilang\n1/3 tengah : dalam batas normal\n1/3 apikal : menghilang	mesial\n1/3 servikal : menghilang\n1/3 tengah : menghilang\n1/3 apikal : menghilang\n\ndistal\n1/3 servikal : menghilang\n1/3 tengah : menghilang\n1/3 apikal : menghilang	Tidak ada	tinggi\nmesial : 0,32 mm, distal : 0,12 mm\nbentuk\nmesial : horizontal, distal : vertikal\ntulang kortikal : tidak ada\nkontinuitas : tidak ada\noutline : tidak ada\ntebal/lebar : tidak ada\ndensitas : tidak ada\ntulang kanselus (spongious)\ndensitas : padat\npola : bulat	radiodensitas lesi : terdapat gambaran radiolusen\nlokasi dan perluasan lesi : pada 1/3 setengah akar sampai apikal akar pada inferior superior gigi 35\nbentuk dan ukuran diameter lesi : 0,72 mm\nbatas tepi : jelas dan tegas\nstruktur interna lesi : tidak ada\nefek lesi terhadap jaringan sekitar : menggeser gigi sebelahnya	tinggi tulang yang ada : tidak ada\nkondisi alveolar crest : terdapat penurunan tulang alveolar crest secara horizontal dan vertikal\nruang periodontal dan lamina dura : menghilang\nrasio mahkota akar : 01:02	radiodensitas bahan restorasi : terdapat gambaran radiopak\nkontur restorasi : over/undercontour : tidak ada\nkonsisi titik kontak : tidak ada\nadaptasi bahan tumpatan dengan basis tumpatan : tidak ada\nimarginal fit pada restorasi indirect : tidak ada	Kista dentigerous\nKista periapikal	4122023032	Ivan Hasan	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
94363937-2505-45e2-89d8-446e54a952a2	-	RKG260524-8351	-	Panoramik	Cempaka putih	20	2024-05-26	Ameloblastoma	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/09e4fa5a-2829-4e76-8973-dcd1b7f93acf.png	PANORAMIK	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023032	Ivan Hasan	drg. Resky Mustafa,M. Kes.,Sp.RKG	Gigi 28	Tidak ada	Tidak ada persistensi gigi	impaksi gigi 18 dan 48	overlap pada gigi 15 dengan 14, 14 dengan 13, 13 dengan 12, 23 dengan 24, 24 dengan 25, 25 dengan 26	Dalam batas normal	Terdapat penurunan tulang alveolar crest pada mesial gigi 35 secara vertikal dan distal gigi 36 secara horizontal	Terdapat gambaran radiolusen dari superior gigi 36 meluas ke condulis mandibula	lantai sinus menyentuh akar gigi posterior rahang atas	\N	\N	WRITE	OPEN	PANORAMIK	\N
dbea3546-c573-4c10-b4e9-45b89aacdc49	-	RKG270524-3462	-	Video oklusal	Cempaka putih	0	\N	\N	\N	OKLUSI	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023032	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	OKLUSI	\N
4ac8bad8-82a0-4230-b188-422bdf17c46e	02	RKG270524-4207	rkg 1	Nn. Nabila / Video Periapikal	Cempaka Putih	3	2024-05-28	-	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/c288d979-8620-48b7-996d-5c2ed1671777.png	PERIAPIKAL	-	-	-	-	-	-	-	-	-	-	4122023025	Amalia Rafa Wulandari	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	https://drive.google.com/drive/folders/1AySrRNdQ9x5FZFagR3wKccQNoE_0YQA7?usp=share_link
a15f5eee-44dc-40c1-9065-7bcde7383e36	01	RKG270524-8949	RKG 1	Ny. X	Korea	24	2024-05-27	Dens invaginatus (dens in dente) menunjukkan berbagai tingkat invaginasi  permukaan email ke bagian dalam gigi	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/6d5fd8a8-4ec2-435f-ab10-4f3555e360f2.png	PERIAPIKAL	Dalam batas normal	Terdapat gambaran radiopak berbentuk oval pada kamar pulpa\t\t\t\t\t\t\t\nTerdapat gambaran radiopak pada saluran akar berbentuk oval dari 1/3 servikal hingga 1/3 tengah	Terjadi penebalan pada 1/3 servikal sampai apikal	Terjadi penebalan pada 1/3 servikal sampai apikal	-	tinggi tulang yang ada: +/- 4mm dari cej di mesial dan distal\t\t\t\t\t\t\t\t\t\t\t\t\t\nruang periodontal dan lamina dura: penebalan lamina dura di seluruh sisi mesial dan distal.\t\t\t\t\t\t\t\nrasio mahkota akar: 1:2	DBN	Terdapat kelainan pada kamar pulpa dan tulang alveolar	DBN	Dens invaginatus dan localized periodontitis stage 1 grade b\nDD: Pulp Stone dan dan localized periodontitis stage 2 grade b\t\t\t\t\t\t\t\nDD: enamel pearls dan localized periodontitis stage 2 grade b	4122023024	Adila Hikmayanti	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
83435e71-44b4-4b2d-b0e2-8d0508b6ea8d	-	RKG270524-1749	RKG 2	Periapikal 2	Cempaka putih	48	2024-05-27	Osteoma	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/66efed4d-25ea-4228-82ff-e018d6bb0468.png	PERIAPIKAL	Terdapat gambaran radiopak pada mahkota gigi 16 dari email sampai dentin	Dalam batas normal	Menghilang pada 1/3 apikal akar	Menghilang pada 1/3 apikal akar	Tidak terdapat furkasi	Adanya penurunan tulang alveolar crest bagian distal gigi 16 secara horizontal	Terdapat gambaran radiolusen pada 1/3 apikal akar dengan batas radiodiffuse (tidak jelas)	Terdapat kelainan pada mahkota, membran periodontal, lamina dura, dan periapikal	Site : 1/3 apikal akar\nSize : kurang lebih 6 mm\nShape : reguler\nSymetri : simetris\nJumlah : 1\nBorder : berbatas tidak jelas\nContent : radiolusen\nAssociation : kerusakan pada tulang alveolar crest	Diagnosis banding : Granuloma dan kista radikuler\n\nPerbedaan\nGranuloma : \npembentukan jaringan granulasi secara berlebihan sebagai respon rangsangan infeksi gigi. Tampak sebagai lesi multilokular pada radiografi dan lebih besar dari ukuran dan bentuk abses\nKista radikuler : \nkumpulan inflamasi kista yang berkembang dari deposit jaringan epitel pada ruang periodontal berlanjut dengan nekrosis pulpa\n\nPersamaan\nGranuloma : radiolusen, shape reguler, simetris\nKista radikuler : radiolusen, shape reguler, simetris\n\nsama” muncul di daerah radikuler atau periradikuler, berasal dari gigi nonvital	4122023032	Ivan Hasan	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
a7541af2-3f03-4747-9cb0-fb9b1f8d3791	3	RKG270524-9704	RKG 2	Nn. B	Indonesia	12	2024-05-27	Karies mencapai pulpa	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/3e5bb346-6b74-4aba-909f-e982651227c0.png	PERIAPIKAL	Terdapat gambaran radiolusen dari email hingga pulpa	Terdapat satu akar dan satu saluran akar (Dalam Batas Normal)	Terputus pada 1/3 apikal pada bagian mesial dan distal	Terputus pada 1/3 apikal pada bagian mesial dan distal	-	Menurun 1,5 cm secara horizontal pada bagian mesial dan 2 cm secara vertikal pada bagian distal	-	Terdapat kelainan pada mahkota, membran periodontal, lamina dura, dan periapikal	-	Karies mencapai pulpa	4122023028	Breaniza Dhari	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
59b1343b-69e6-402b-ac26-715337ddbeba	2	RKG280524-4815	02	Tn. Randy Ramadhiansa / Periapikal/ drg. Resky	jl. ivo	27	2024-05-28	Karies kelas II dari email mencapai pulpa pada bagian distal \nDD : karies kelas II dari email mencapai dentin pada bagian distal	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/9a7761f1-ea6e-4e95-9a59-9f8b49756c35.jpeg	PERIAPIKAL	terdapat radiolusen pada distal gigi 46 dari email mencapai pulpa dan radiopak dari email mencapai dentin	terdapat dua akar dan dua saluran akar	dalam batas normal	dalam batas normal	dalam batas normal	mesial : jarak dari CEJ 0,9 mm\ndistal : jarak dari CEJ 1 mm \nbentuk : horizontal	dalam batas normal atau tidak ada	kelainan pada mahkota	terdapat lesi radiolusen dari email mencapai pulpa pada mahkota	karies kelas II dari email mencapai pulpa pada bagian distal \nDD : kelas II dari email mencapai dentin pada bagian distal	4122023033	Ivo Resky Primigo	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
ddac8f19-9b34-4f67-a222-70222e695ea7	4	RKG270524-1238	RKG 2	Tn. B	Indonesia	53	2024-05-27	Abrasi gigi berasal dari bahasa latin ”Abrader” yang artinya mengikis. Dalam arti lain abrasi gigi merupakan keausan patologis yang melibatkan jaringan keras melalui proses mekanik yang disebabkan oleh benda asing (Hanif dkk, 2015). Abrasi gigi merupakan hilangnya substansi gigi melalui proses mekanisme yang abnormal, abrasi pada daerah serivikal banyak ditemukan pada orang berusia lanjut yang menyikat gigi dengan cara kurang benar.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/41f645c0-8f33-40c6-be92-782b970d4d63.png	PERIAPIKAL	Terdapat gambaran radiolusen pada servikal mesial gigi	Terdapat satu akar dan satu saluran akar (Dalam Batas Normal)	Terputus pada 1/3 servikal pada bagian mesial dan distal	Terputus pada 1/3 servikal pada bagian mesial dan distal	-	Menurun 0,2 cm secara vertikal pada bagian mesial dan 0,4 secara vertikal pada bagian distal	-	Terdapat kelainan pada mahkota, membran periodontal, dan lamina dura	-	Abrasi	4122023028	Breaniza Dhari	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
7904ab4a-ac27-468e-be21-041a0401d6f7	02	RKG270524-3812	RKG 1	Nn. X	India	12	2024-05-27	Condensing osteitis	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/08459030-ccb4-4f7b-9623-cd0a3755e5b8.png	PERIAPIKAL	Terdapat kerusakan mahkota disto oklusal dan radiopak pada email meluas hingga ke kamar pulpa	Terlihat 2 akar dan 2 saluran akar, pada 1/3 akar distal terlihat gambaran radiopak	Menghilang pada 1/3 tengah sampai 1/3 apikal	Menghilang pada 1/3 tengah sampai 1/3 apikal	DBN	Terjadi penurunan tulang sebanyak 4mm	Terdapat gamabran radiopak berada di 1/3 apikal disto lateral apex gigi 36 berbentuk oval beraturan dan berdiameter +/- 6-8 mm dengan batas tidak jelas dan tidak tegas	Terdapat kelainan  pada mahkota, akar, periapikal, lamina dura, membran periodontal	Lesi radiopak berada di 1/3 apikal disto lateral apex gigi 36 berbentuk oval beraturan dan berdiameter +/- 6-8 mm dengan batas tidak jelas dan tidak tegas	Condensing osteitis disertai localized periodontitis stage 1 grade c\nDD: Idiopatic bone sclerosis dan localized periodontitis stage 2 grade c\t\t\t\t\t\t\nDD: cementoblastoma dan localized periodontitis stage 2 grade c	4122023024	Adila Hikmayanti	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
535cc93b-66e3-4c9f-9af7-34f034b3931d	01	RKG270524-9401	RKG 1	Salwa	Jl. Cempaka Baru IV no. 5	30	2024-05-27	Pulp Stone	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/a8f64e64-9ba3-4efa-bd53-a4ca18975099.png	PERIAPIKAL	DBN	Akar tunggal dan lurus terdapat radiopak pada bagian 2/3 dari apeks, akar terbuka	Melebar	DBN	-	DBN	DBN	Kelainan pada akar, membran periodontal, laminadura	-	Pulp Stone	4122023045	Shabrina Ghisani	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	FINISH	OPEN	PERIAPIKAL	\N
a44752f3-049d-44ce-b623-9808359afb07	03	RKG280524-3054	RKG 2	Tn. X	Jl. Cempaka tengah V No. 20	0	2024-05-28	Impaksi gigi 23 tipe II	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/47d5b73b-4b61-4027-a3f1-e9311d20ac48.jpeg	OKLUSI	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023045	Shabrina Ghisani	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	Site : distal gigi 25 hingga distal gigi 21\nSize : -+ 5cm\nShape : irregular\nSymetri : Asimetri\nJumlah : 1\nBorder : Berbatas jelas dan tegas\nContent : lesi radiopak yang berbatas jelas\nAssociation : -	Impaksi gigi 23 tipe II\nDD : Impaksi gigi 23 tipe III, Impaksi gigi 23 tipe IV	FINISH	OPEN	OKLUSI	\N
68eac84d-f53d-4464-a127-f67856e4fd6e	06	RKG270524-9157	rkg 2	Ny. B/Periapikal Intepretasi rkg 2	Korea Selatan	42	2024-05-27	Kista periapikal atau radikular adalah kista yang paling umum terjadi pada rahang. Kista ini dianggap sebagai kista inflamasi daripada kista odontogenik yang sedang berkembang. Kista ini selalu dikaitkan dengan gigi nonvital. Kista periapikal tidak dapat dibedakan secara radiografi dari granuloma ketika masih kecil.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/51d0a923-8001-45fa-a9bc-62db3eb849e6.png	PERIAPIKAL	dalam batas normal	akar\t\t\t\t\t                terdapat satu akar, tunggal\t\t\t\t\t\t\t\t\t\t\nsaluran akar\t\t\t\t\tdalam batas normal	lamina dura sisi mesial (lateral dan medial), distal (lateral dan medial). : # 1/3 servikal: Terputus \n\t\t                                                                                                       : #1/3 tengah: Dalam Batas Normal \n                                                                                                               :#1/3 apikal: Terputus	lamina dura sisi mesial (lateral dan medial), distal (lateral dan medial). : # 1/3 servikal: Terputus \n\t\t                                                                                                       : #1/3 tengah: Dalam Batas Normal \n                                                                                                               :#1/3 apikal: Terputus	tidak terdapat. furkasi	alveolar crest\t\t\t\t\tMesial\t\t                                            Distal\t\t\t\ni. tinggi\t\t\t\t\tmenurun secara horizontal, 2,54mm\t\tmenurun secara horizontal 1,77mm\t\t\t\nii.bentuk\t\t\t\t\tsegitiga\t\t                                           segitiga \t\t\t\niii.tulang kortikal :\t# ada/tidak\t\t\t\tada\t\tada\t\t\t\n\t# kontinuitas\t\t\t\tTidak Ada\t\tTidak Ada \t\t\t\n\t# outline\t\t\t\tTidak Ada\t\tTidak Ada \t\t\t\n\t# tebal/lebar\t\t\t\tTebal\t\ttebal\t\t\t\n\t# densitas\t\t\t\tNormal\t\tnormal\t\t\t\niv.tulang kanselus (spongious) : -densitas\t\t\t\t\tPadat\t\tpadat\t\t\t\n-pola\t\t\t\t\tGepeng\t\tgepeng	radiodensitas lesi\t\t\t\t                       \tRadiolusen\t\t\t\t\t\t\nlokasi dan perluasan lesi\t\t\t\t     \tMesial gigi 42 meluas hingga mesial gigi 32\t\t\t\t\t\t\nbentuk dan ukuran diameter lesi\t\t\t\t  irreguler, 2,76cm\t\t\t\t\t\t\nbatas tepi\t\t\t\t\t                                     Diffuse\t\t\t\t\t\t\nstruktur interna lesi\t\t\t\t\t                       Radiolusen\t\t\t\t\t\t\nefek lesi terhadap jaringan sekitar\t\t\t\t\tTidak Ada	terdapat gambaran radiolusen pada periapikal	radiodensitas lesi\t\t\t\t                       \tRadiolusen\t\t\t\t\t\t\nlokasi dan perluasan lesi\t\t\t\t     \tMesial gigi 42 meluas hingga mesial gigi 32\t\t\t\t\t\t\nbentuk dan ukuran diameter lesi\t\t\t\t  irreguler, 2,76cm\t\t\t\t\t\t\nbatas tepi\t\t\t\t\t                                     Diffuse\t\t\t\t\t\t\nstruktur interna lesi\t\t\t\t\t                       Radiolusen\t\t\t\t\t\t\nefek lesi terhadap jaringan sekitar\t\t\t\t\tTidak Ada	Kista Periapikal\t\t\t\t\t\t\nDD: granuloma periapikal, abses periapikal Kista Residual	4122023025	Amalia Rafa Wulandari	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
9d1e9874-e892-4a94-84ad-55dbc06e017d	01	RKG270524-5327	02	ny. X	jl. raden fatah	0	2024-05-27	Fibroma gigi adalah tumor jinak yang paling umum ditemukan di rongga mulut,\nterutama di dalam gingiva (gusi) atau pada mukosa bukal (bagian dalam pipi).	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/2d18ad31-20a5-44b7-b461-9858676deaa4.jpg	PANORAMIK	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023034	Jessica Putri Souisa	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	-	-	-	48 dan 38 impaksi	Kondisi mahkota: Gigi 14 overlap dengan 15 Gigi 24 overlap dengan 23 Gigi 45 overlap dengen 44	dua akar (divergen)	DBN	Terdapat lesi radiolusen berbatas tegas dan jelas pada rahang bawah kanan dan kiri yaitu pada distal gigi 36 meluas ke mesial 35 dan mesial gigi 45 meluas ke mesial 46	Dalam batas normal	\N	\N	WRITE	OPEN	PANORAMIK	-
a867893f-4289-4bda-8732-7aaa623c92b8	02	RKG270524-3875	RKG 1	Rian	Jl. Rambutan V no. 8	0	2024-05-27	TMJ Grade 1	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/6f0d2dd3-9fb9-4d1f-b9d7-87cf2b64a44a.png	PANORAMIK	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023045	Shabrina Ghisani	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	tidak ada	tidak ada	tidak ada	tidak ada	DBN	DBN	DBN	DBN	DBN	\N	\N	FINISH	OPEN	PANORAMIK	\N
ef991d29-01ae-4f0f-b91e-13d54bda7bd7	-	RKG280524-5037	RKG 2	Mr. B	jl. bekasi raya	0	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023034	\N	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
c9cf5fb5-6f52-4323-b0bc-6f6559791ab7	08	RKG280524-4908	rkg 2	Ny. U/ oklusal intepretasi rkg 2	Depok	36	2024-05-28	impaksi gigi adalah sebutan untuk gigi yang tidak bisa tumbuh sehingga tertanam di dalam gusi, baik sebagian maupun sepenuhnya.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/0abb693b-991b-45d1-a6c7-d70b4a68a11d.png	OKLUSI	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023025	Amalia Rafa Wulandari	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	Mahkota 43 berada diantara gigi 41dan 31\nposisi gigi 43 vertikal oblique antara gigi 41 dan gigi 44\nAkar gigi 43 berada di 1/3 apikal gigi 42\nAkar 43 berada pada lingual gigi 42 dan gigi 44\nMahkota gigi 33 berada 1/3 apikal gigi 32 dan 1/3 apikal gigi 31\nposisi gigi 33 vertikal antara gigi 31 dan 32\nAkar gigi 33 berada pada labial gigi 41 dan gigi 42	Impaksi gigi 33 Tipe 5, Impaksi gigi 43 Tipe 3\nDiagnostic Banding: Impaksi Gigi Caninus Tipe 5, Tipe 1	WRITE	OPEN	OKLUSI	\N
4d699448-3174-4b5e-ba64-005474349d38	2	RKG280524-5892	2	RKG 1 : Periapikal 2 : Ny. B	Jl.B	22	\N	\N	\N	PANORAMIK	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023039	\N	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PANORAMIK	\N
69368a99-323f-4270-aaa0-7fe3728f5121	6	RKG280524-9287	6	RKG 2 : Periapikal : Tn. E	Jl. E	22	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023039	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PERIAPIKAL	\N
3db5f8d3-0f3a-42c7-8e90-a3c0ed552c0c	1	RKG270524-9098	RKG 1	Tn. B	Indonesia	14	2024-05-27	Kista nasopalatina (KNP) dikenal juga dengan nama incisive canal cyst, anterior middle cyst, dan anterior middle palatine cyst yang diduga berasal dari sisa embrionik duktus nasopalatina yang menghubungkan antara cavum nasi dan maksila anterior pada perkembangan fetus. Banyak faktor predisposisi yang mempengaruhi terjadinya KNP diantaranya faktor trauma lokal saat proses mengunyah atau kesalahan pemasangan gigi palsu, infeksi bakteri, proliferasi spontan dan faktor ras atau genetik.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/0f08ad86-a0e6-4f07-b045-4a292cef536c.png	PANORAMIK	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023028	Breaniza Dhari	drg. Resky Mustafa,M. Kes.,Sp.RKG	-	-	Terdapat persistensi gigi 65	-	Gigi 14 terdapat gambaran radioopak pada bagian mesial gigi overlap dengan gigi 13, Gigi 15 terdapat gambaran radioopak pada bagian mesial gigi overlap dengan gigi 14, Gigi 24 terdapat gambaran radioopak pada bagian mesial gigi overlap dengan gigi 23 dan bagian distal gigi overlap dengan gigi 25, Gigi 25 terdapat gambaran radioopak pada bagian mesial gigi overlap dengan gigi 24 dan bagian distal gigi overlap dengan gigi 23, Gigi 18, 28, 38, 48 terindikasi impaksi	Dalam Batas Normal (18, 28, 38, 48 terjadi pembentukan akar mencapai 1/3 cervical terindikasi impaksi)	Dalam Batas Normal	Terdapat gambaran radiolusen pada apikal gigi 15 hingga gigi 25 dan meluas ke sinus maksila	Terdapat gambaran radiolusen pada akar gigi 14 sampai gigi 25 dan meluas hingga sinus maksila	\N	\N	WRITE	OPEN	PANORAMIK	\N
4cd3e169-1059-4fe3-9fac-44e2029d9324	2	RKG270524-4948	2	Nn. B	Indonesia	0	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023028	\N	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PERIAPIKAL	\N
1dad2a4e-a5c0-40a9-aa7e-4c9f21b665fb	2	RKG270524-3748	2	Nn. B	Indonesia	0	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023028	\N	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PERIAPIKAL	\N
fdaea22d-78a5-41b6-ae50-6209ab9c6fd0	1	RKG270524-4020	RKG 1	Nn.X/Interpretasi Periapikal 1	RSGM Eastman, London	15	2024-05-27	Dense Bone Island\nDense Bone Island disebut juga dengan istilah enostosis / osteosclerosis idiopatik merupakan varian anatomi yang didefinisikan sebagai lesi radiopak variasi normal/ adanya pertumbuhan tulang berlebih.\n\nEtiologi:\nEtiologinya masih belum jelas	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/9a5a1b2f-28d3-48ac-b0c1-4c362963b1c3.png	PERIAPIKAL	Dalam batas normal	Gigi 34 memiliki 1 akar yang lurus, 1 saluran akar	Dalam batas normal	Dalam batas normal	Tidak memiliki furkasi	Dalam batas normal	Gambaran radioopak berbatas jelas dan tegas	Terdapat kelainan pada periapikal	Site: Bagian atas : 1/3 apeks akar antara gigi 34 dan 35 , Bagian bawah: mengenai foramen mentalis, Bagian horizontal: apikal distal gigi 34 meluas ke mesial gigi 35.\nSize: 9x10 mm\nShape: irreguler\nSymmetry: Asimetri\nJumlah: 1\nBorder: Berbatas jelas dan tegas \nContent: lesi radioopak \nAssociation: -	Diagnosis: Dense Bone Island\nDd: Cementoblastoma, Odontoma complex	4122023037	Khairunnisa Nabiilah Putri	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
8f923929-5088-4102-99cd-ccbdd7998ffa	2	RKG270524-4409	RKG 1	Nn. B	Indonesia	24	2024-05-27	Osteochondroma adalah salah satu tumor jinak pada tulang yang terdiri dari sekumpulan proliferasi tulang dengan kartilago hyalin sebagai penutupnya dan tidak ada daerah transisi antara osteochondroma dan jaringan tulang normal. Osteochondroma biasanya ditemukan pada metafisis tulang panjang dan tulang pipih, jarang terjadi di daerah kraniomaksilofasial.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/33314c1c-ec95-4f0d-8a41-5907ff129d80.png	PERIAPIKAL	Terdapat radiolusen dari email sampai dentin	Dalam Batas Normal	Melebar pada 1/3 apikal	Terputus pada 1/3 apikal	Tidak terlihat	Menurun 3-5 mm secara vertikal	Terdapat gambaran radiolusen berbatas diffuse pada apeks mesial gigi 33 sampai apeks distal gigi 42 berbentuk irregular	Terdapat kelainan pada mahkota, membran periodontal, lamina dura, furkasi, alveolar crest, dan periapikal	Site : Inferior atau periapikal gigi 32 - 41\nSize : ± 2 - 2,5 cm\nShape : Irregular \nSymetri : Asimetris \nJumlah : 1\nBorder : Berbatas diffuse\nContent : Radiolusen	Osteochondroma	4122023028	Breaniza Dhari	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
fd9b9a6a-1410-4d37-bdf6-c068f21cc12e	5	RKG270524-4942	RKG 2	Ny.Y/Interpretasi Periapikal 2	South-east Iran	22	2024-05-27	Pulp stone merupakan suatu kalsifikasi yang muncul di dalam jaringan pulpa dan dapat juga melekat atau bahkan tertanam dalam dentin. pulp stone juga bias disebut sebagai dentikel. \n\nEtiologi:\nPenyebabnya tidak diketahui, dan tidak ada bukti yang kuat bahwa pulp stone ini terkait dengan gangguan sistemik atau pulpa.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/3cff30ad-abff-45f4-a344-30d709af636c.png	PERIAPIKAL	Terdapat gambaran radiopak pada 1/3 mahkota gigi 34	Tidak dapat diinterpretasikan karena foto terpotong atau apikal cutting	Bagian mesial gigi melebar pada 1/3 servikal gigi\nBagian distal gigi tidak dapat diinterpretasikan karena apex cutting	Bagian mesial gigi menghilang\nBagian distal gigi tidak dapat diinterpretasikan karena apex cutting	Dalam batas normal	Dalam batas normal	Tidak ada	Terdapat kelainan pada mahkota, akar, membran periodontal, lamina dura	Tidak ada	Diagnosis: Pulp Stone\nDd : Pulpal Sclerosis, dens invaginatus	4122023037	Khairunnisa Nabiilah Putri	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
acfefb85-8150-4d18-ad72-7a7c6e923cda	04	RKG280524-4415	RKG 1	Haikal	Jl. Jambu no 7	17	2024-05-28	Karies mencapai dentin disertai abses dini	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/288a628a-8711-4eb4-9f09-dafff0eff129.jpeg	PERIAPIKAL	Terdapat gambaran radiolusen berupa karies dari mahkota hingga dentin pada bagian oklusal	Terlihat 2 akar dan saluran akar	Pada mesio medial 1/3 servikal melebar sampai 1/3 apikal\nPada disto lateral 1/3 servikal melebar sampai 1/3 apikal	Pada bagian distal lamina dura terputus di 1/3 servikal	DBN	Pada bagian mesial berbentuk runcing dan jarak dari CEJ 0,4 mm\nPada bagian distal tidak dapat di interpretasi	DBN	Terdapat kelainan pada mahkota, membran, laminadura, alv crest	\N	Karies mencapai dentin disertai abses dini\nDD = karies mencapai pulpa disertai abses apikalis kronis	4122023045	Shabrina Ghisani	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	FINISH	OPEN	PERIAPIKAL	\N
a102846b-c083-43e5-b876-0fb77ff740fd	09	RKG280524-4835	rkg 2	Nn. Mutia/ Video Oklusal	Jakarta	0	2024-05-28	-	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/e06839ee-5629-4b63-aa86-9fc775766d0e.png	OKLUSI	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023025	Amalia Rafa Wulandari	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	-	-	WRITE	OPEN	OKLUSI	https://drive.google.com/drive/folders/1KDsyMf5ZZffN9T8FORLbvJoJYXw-giqL?usp=share_link
ca610a71-c930-476b-82c6-5a6098000dd7	03	RKG280524-2867	RKG 1	Tn. T	Thailand	48	2024-05-28	Ameloblastoma	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/7b61a9b5-bb47-4dd5-abe9-398d990a7fb5.png	PERIAPIKAL	Tidak dapat diinterpretasi	Tidak dapat diinterpretasi	Tidak dapat diinterpretasi	Tidak dapat diinterpretasi	Tidak dapat diinterpretasi	Puncak alveolar crest mengalami penurunan secara horizontal sebanyak 4-5 mm.	Tidak dapat diinterpretasi	Terdapat kelainan di tulang alveolar	Site: Pada area distal gigi 35 meluas sampai ke area gigi 36-37.  Berada di  alveolus pada gigi 36-37.\nSize: + - 2-3 cm \nShape:  regular\nSymmetri: simetri\nJumlah: 1\nBorder: batas tidak jelas dan tidak tegas \nContent:  Lesi radiolusen berbatas tidak jelas dan tidak tegas.	Ameloblastoma\nDD: Odontogenic keratocyst\nDD: Ameloblastic fibroma	4122023024	Adila Hikmayanti	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
31145eed-a7de-4570-8183-c5eb5f2f4667	3	RKG270524-4013	RKG 1	Nn. B	Indonesia	20	2024-05-27	Granuloma memiliki batas tegas dan tidak jelas. Granuloma itu sendiri terjadi akibat nekrotik kronis pada orang- orang dengan daya tahan tubuh yang tinggi. Jaringan granulasi yang terbentuk merupakan rangsangan kronis agar bakteri tidak menyebar ke seluruh tubuh. Penyebab perkembangan granuloma adalah matinya pulpa, diikuti oleh suatu infeksi ringan atau iritasi jaringan periapikal yang merangsang suatu reaksi selular produktif. Granuloma hanya berkembang beberapa saat setelah pulpa mati.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/6ec3d669-9034-47ba-a588-8b475ff41a4b.png	PERIAPIKAL	Mahkota tidak dapat diinterpretasi (terpotong pada bagian email) dan terdapat gambaran radiolusen dari email sampai kamar pulpa	Terdapat satu akar dan satu saluran akar (Dalam Batas Normal)	Terputus 1/3 apikal pada bagian mesial dan distal	Terputus 1/3 apikal pada bagian mesial dan distal	-	Menurun 1,5 cm secara horizontal pada bagian mesial dan 2 cm secara vertikal pada bagian distal	Radiodensitas lesi: Radiolusen\t\t\t\t\t\t\t\nLokasi dan perluasan lesi: Apikal gigi 41\t\t\t\t\t\t\t\nBentuk dan ukuran diameter lesi: Regular 1,2 cm\t\t\t\t\t\t\t\nBatas tepi: Jelas\t\t\t\t\t\t\t\nStruktur interna lesi: Radiolusen\t\t\t\t\t\t\t\nEfek lesi terhadap jaringan sekitar: -	Terdapat kelainan pada mahkota, membran periodontal, lamina dura, dan periapikal	Terdapat gambaran radiolusen pada apikal gigi 41	Karies mencapai pulpa disertai tanda patologis periapikal sesuai dengan gambaran suspect radiodiagnosis granuloma	4122023028	Breaniza Dhari	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
0452c08e-08ac-4a4a-b613-97a28547f4ae	05	RKG270524-9246	rkg 2	Tn. Y/ Panoramic Intepretasi rkg 2	Indonesia	29	2024-05-27	Kista dentigerous adalah kista odontogenik jinak yang berhubungan dengan mahkota gigi permanen yang belum erupsi.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/3c1eb342-1a21-429d-bed1-284b3a645701.png	PANORAMIK	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023025	Amalia Rafa Wulandari	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	-	-	-	impaksi gigi 38,48	gigi 13 overlapping dengan gigi 14, gigi 14 overlapping dengan gigi 15, gigi 15 overlapping dengan gigi 16. gigi 23 overlapping dengan gigi 24, gigi 24 overlapping dengan gigi 25, gigi 25 overlapping dengan gigi 26. gigi 34 overlapping dengan gigi 35, gigi 35 overlapping dengan gigi 36	dalam batas normal	dalam batas normal	Terdapat area radiolusen dengan batas jelas tegas pada apikal gigi 37 meluas sampai saluran akar gigi 38 meluas ke inferior border of mandibula regio kiri	Dalam Batas Normal	\N	\N	WRITE	OPEN	PANORAMIK	\N
5325df72-d86d-406c-a1cf-c5b7b498800c	03	RKG270524-8802	rkg 2	Nn. N/ Periapikal Intepretasi rkg 2	Thailand	18	2024-05-27	odontoma adalah tumor odontogenik yang memiliki sifat klinis jinak, dianggap sebagai kelainan perkembangan . Tumor odontogenik ini terdiri dari jaringan email, dentin, sementum dan pulpa.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/b34e61a0-92ab-486f-be54-c9f1539a8c33.png	PERIAPIKAL	dalam batas normal	dalam batas normal	dalam batas normal	Lamina dura terputus dibagian apikal akar distal dan mesial gigi 47	dalam batas normal	dalam batas normal	Gambaran radiopak pada akar gigi 47 distal	terdapat kelainan pada lamina dura dan periapikal	SITE\nBagian distal gigi 47 melebar hingga ramus mandibula dextra.\nbagian vertikal: tulang alveolar meluas ke batas inferior mandibula\nSIZE\nKurang lebih 4x3cm\nSHAPE\nIrreguler\nSYMETRY\nAsimetri\nBORDER\nBerbatas Jelas\nCONTENT\nLesi Radiopak\n ASSOCIATION\ntidak melibatkan resorpsi akar 47	odontoma \ndd: ossifying fibromas, dense bond island, cemento osseus dysplasia	4122023025	Amalia Rafa Wulandari	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
fe15db59-1748-4bc2-8bfa-b85377ea7e37	1	RKG270524-9220	RKG 2	Nn. B	Brazil	12	2024-05-27	Tumor odontogenik adenomatoid (AOT) adalah tumor odontogenik jinak, noninvasif dan tidak menimbulkan rasa sakit yang jarang terjadi.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/696529f0-3b78-48c9-a10e-5aa2d5f8d07c.png	PANORAMIK	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023028	Breaniza Dhari	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	-	-	Terdapat persistensi gigi 65, 75, 83, 85	-	Terdapat gambaran radioopak dari email hingga dentin pada gigi 26, 35 dan 46, Terdapat gambaran radioopak pada gigi 13 bagian distal gigi overlap dengan gigi 14	Dalam Batas Normal	Dalam Batas Normal	Terdapat gambaran radiolusen pada apikal gigi 41 sampai gigi 83	Dalam Batas Normal	\N	\N	WRITE	OPEN	PANORAMIK	\N
0c767131-4ff4-4c9c-9140-a26dec11fcd3	2	RKG270524-2456	RKG 2	Ny. B	Indonesia	57	2024-05-27	Calcifying Epithelial Odontogenic Tumor (CEOT) adalah neoplasma jinak epitel odontogenik dengan karakteristik pertumbuhan yang lambat dan agresif, cenderung menyerang tulang dan jaringan lunak sekitarnya dengan prevelensi 10 – 15% lebih rendah dari ameloblastoma, ditandai dengan adanya epitel yang bersusun seperti lapisan.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/55d715f2-1b93-4c2c-8e40-c1541b540983.png	PERIAPIKAL	Tidak terlihat	Tidak terlihat	Tidak terlihat	Tidak terlihat	Tidak terlihat	Tidak terlihat	Tidak terlihat	Terdapat kelainan pada mahkota, akar, membran periodontal, lamina dura, furkasi, alveolar crest, dan periapikal	Site : Inferior gigi 36 \nSize : ± 2 cm\nShape : Irregular \nSymetri : Asimetris \nJumlah : 1\nBorder : Berbatas diffuse\nContent : Radiolusen disertai dengan radioopak	Calcifying Epithelial Odontogenic Tumor (Tumor Pindborg)	4122023028	Breaniza Dhari	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
e02323d5-f2c8-4ec2-81fa-f04a731fd680	4	RKG270524-5998	RKG 1	Tn. B	Eropa	15	2024-05-27	Traumatic Dental Injuries (TDIs) sebagian besar terjadi pada anak-anak dan dewasa muda. TDIs mungkin berdampak buruk pada kesejahteraan sosial dan psikologis pasien. Fraktur gigi diklasifikasikan menurut jaringan yang retak dan keterlibatan pulpa, dan mencakup fraktur email, fraktur mahkota tanpa komplikasi (fraktur email dan fraktur email-dentin), fraktur mahkota dengan komplikasi (fraktur email-dentin dengan pulpa terbuka), dan fraktur mahkota-akar dan fraktur akar.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/a8010419-0fa6-463e-9599-da7bf5bc2da9.png	PERIAPIKAL	Terdapat gambaran radiolusen berupa fraktur dari email sampai kamar pulpa (1/3 mahkota)	Terdapat satu akar dan satu saluran akar (Dalam Batas Normal)	Melebar 1/3 servikal pada bagian mesial	Terputus 1/3 servikal pada bagian mesial dan distal	-	Menurun 0,25 cm secara vertikal pada bagian mesial	-	Terdapat kelainan pada mahkota, membran periodontal, dan lamina dura	-	Fraktur Mahkota (Klasifikasi Ellis III)	4122023028	Breaniza Dhari	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
3d95fee5-93e6-4097-a120-8906f6d30c48	5	RKG280524-5552	RKG 2	Ny. B	Amerika	65	2024-05-28	Fraktur mandibula merupakan patah tulang rahang yang terjadi karena trauma fisik seperti kecelakaan mobil, kecelakaan olahraga, atau pukulan langsung ke rahang.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/fd7897ae-949a-4d1e-8e89-42067d45e85f.png	OKLUSI	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023028	Breaniza Dhari	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	Site : Antara gigi 41 bagian distal dan 42 bagian mesial secara vertikal\nSize :  1,4 cm \nShape : Regular \nSymetri : Asimetris \nJumlah : 1\nBorder : Berbatas diffuse\nContent : Radiolusen	Mandibular fracture	WRITE	OPEN	OKLUSI	\N
e3b11448-40df-403b-a5ff-fb3fba6a61e4	4	RKG280524-8082	4	RKG 1 : Periapikal : Tn. D	Jl.D	22	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023039	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PERIAPIKAL	\N
f96495a2-a98e-4c75-bde3-f8dda638590e	5	RKG280524-5722	5	RKG 1 : Video Periapikal : Case report : An X dan An Y	Jl. X	22	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023039	\N	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PERIAPIKAL	\N
559f5752-aefe-4860-a87e-6bf0b6aa3bb4	10	RKG280524-4647	10	RKG 2 : Oklusal 1 : Ny. I	Jl. I	22	\N	\N	\N	OKLUSI	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023039	\N	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	OKLUSI	\N
5cff3000-bd67-4032-a744-4af8726f50e8	2	RKG270524-1012	RKG 1	Nn.Y/Interpretasi Periapikal 1	RSGM Eastman, London	17	2024-05-27	Dense Bone Island\nDense Bone Island disebut juga dengan istilah enostosis / osteosclerosis idiopatik merupakan varian anatomi yang didefinisikan sebagai lesi radiopak variasi normal/ adanya pertumbuhan tulang berlebih.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/dfedda8f-a6ed-4355-aa51-329b9b6f5d35.png	PERIAPIKAL	Mahkota gigi tidak dapat diinterpretasikan (cups terpotong)	Gigi 34: Terdapat 1 akar tunggal dan 2 saluran akar	Membran periodontal menghilang pada 1/3 apikal mesio lateral dan disto lateral	Lamina dura menebal pada 1/3 apikal mesio lateral dan disto lateral	Tidak ada	Tinggi: terjadi penurunan tulang alveolar bagian distal sebanyak 0,47 mm \nbentuk: segitiga (Mesial-Distal)\ntulang kortikal: ada, gepeng padat	- Radiodensitas lesi: radiopak\n- lokasi dan perluasan lesi: lesi 1: 1/3 servikal distal  gigi 34, lesi 2: 1/3 apikal distal gigi 34\t\n- Bentuk dan ukuran diameter lesi: lesi 1: oval tidak beraturan dan berdiameter 2.6 mm, lesi 2: oval tidak beraturan dan berdiameter 6.5 mm\t\n- Batas tepi: jelas dan tegas\n- Struktur interna lesi: radiopak\n- Efek lesi terhadap jaringan sekitar: Tidak ada	Terdapat kelainan pada alveolar crest,	- Radiodensitas lesi: radiopak\n- lokasi dan perluasan lesi: lesi 1: 1/3 servikal distal  gigi 34, lesi 2: 1/3 apikal distal gigi 34\t\n- Bentuk dan ukuran diameter lesi: lesi 1: oval tidak beraturan dan berdiameter 2.6 mm, lesi 2: oval tidak beraturan dan berdiameter 6.5 mm\t\n- Batas tepi: jelas dan tegas\n- Struktur interna lesi: radiopak\n- Efek lesi terhadap jaringan sekitar: Tidak ada	Diagnosis: Dense Bone Island\nDd : Cementoblastoma dan periapical cemento-osseous dysplasia	4122023037	Khairunnisa Nabiilah Putri	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
171743c9-01e2-4e13-9c6b-ba68fe7fedd0	01	RKG270524-6487	01	Tn. X	Jl. India benua antartika	0	2024-05-27	abses pada jaringan periodontal yang menyebabkan rasa sakit, ketidaknyamanan, dan mengakibatkan gigi goyang dan terlepas ketika tidak dirawat.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/f470a0b2-970e-487a-8984-8d0e1472bec3.jpg	PERIAPIKAL	11 DBN	Terjadi penumpulan pada 1/3 apeks akar	1/3 servikal: hilang\n1/3 Tengah: hilang\n1/3 apikal: hilang	Mesio lateral : hilang \nDisto lateral: hilang	-	alveolar crest\nTINGGI\nMesial: 4.8mm dari CEJ\t\nDistal: 5.4mm dari CEJ\t\t\t\nBENTUK\nMesial: Kerusakan tulang dalam arah horizontal\t\nDistal: Kerusakan tulang dalam arah horizontal\t\t\t\nTULANG KORTIKAL\ntidak	radiodensitas lesi: radiolusen\t\t\t\t\t\t\t\nlokasi dan perluasan lesi: Lokasi di 1/3 apikal hingga 1/3 tengah akar, meluas hingga sisi mesial akar 12\t\t\t\t\t\t\t\nbentuk dan ukuran diameter lesi: Bentuk bulat dan diameter >1mm\t\t\t\t\t\t\t\nbatas tepi: Diffuse\t\t\t\t\t\t\t\nstruktur interna lesi: Radiolusensi berkabut\t\t\t\t\t\t\t\nefek lesi terhadap jaringan sekitar: Hilangnya lamina dura dan ruang periodontal	terdapat lesi Radiolusensi berkabut pada apeks gigi 11	radiodensitas lesi: radiolusen\t\t\t\t\t\t\t\nlokasi dan perluasan lesi: Lokasi di 1/3 apikal hingga 1/3 tengah akar, meluas hingga sisi mesial akar 12\t\t\t\t\t\t\t\nbentuk dan ukuran diameter lesi: Bentuk bulat dan diameter >1mm\t\t\t\t\t\t\t\nbatas tepi: Diffuse\t\t\t\t\t\t\t\nstruktur interna lesi: Radiolusensi berkabut\t\t\t\t\t\t\t\nefek lesi terhadap jaringan sekitar: Hilangnya lamina dura dan ruang periodontal	Abses periodontal e.c plak dan kalkulus diperberat titik kontak buruk dan moderate chronic periodontitis localized e.c plak dan kalkulus diperberat titik kontak buruk\t\t\t\t\t\t\t\n\nDD\nAbses dentoalveolar e.c plak dan kalkulus diperberat titik kontak buruk dan moderate chronic periodontitis localized e.c plak dan kalkulus diperberat titik kontak buruk	4122023034	Jessica Putri Souisa	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
13871a81-9019-4857-be33-137221ef397c	01	RKG270524-4532	RKG 1	Ny. XY	jl. Raden fatah	0	\N	bentuk kelainan pada gigi, dimana satu benih gigi terbagi menjadi dua. Hal tersebut disebabkan karena proses pemisahan yang tidak sempurna saat perkembangan gigi.	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023034	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
1b9a08a0-7dd2-495d-9136-7e6a91f9ee14	-	RKG270524-6950	-	Periapikal 1	-	0	2024-05-27	DBN	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/7c46dbfc-937f-4b8c-9b48-5df06be12c8d.jpg	PERIAPIKAL	DBN	DBN	DBN	DBN	DBN	DBN	DBN	DBN	DBN	DBN	4122023024	\N	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
fada193b-abab-4447-8ad3-d8ee4f13f315	01	RKG270524-2156	01	NY. X	Korea	24	2024-05-27	Dens Invaginatus	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/cb905153-3f3e-4b2f-8609-2cb4153e0f79.png	PERIAPIKAL	DBN	DBN	DBN	DBN	DBN	DBN	DBN	DBN	DBN	Dens invaginatus dan penurunan tulang mencapai 1/3 servikal akar mild periodontitis localized	4122023024	Adila Hikmayanti	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	DBN
d0c79902-b701-4ae3-9da7-eb525dd3c16a	9	RKG270524-2953	RKG 2	Ny.D/Interpretasi Periapikal Rkg 2	São Paulo, Brazil	29	2024-05-27	Hipercementosis adalah pengendapan sementum yang berlebihan pada akar gigi. Dalam kebanyakan kasus, penyebabnya tidak diketahui.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/c8b74d43-52e4-4f56-9bbd-6a99af0311e9.png	PERIAPIKAL	terdapat gambaran radiopak pada mahkota gigi dari email hingga dentin	gigi 36 terdapat 2 akar dengan 2 saluran akar	Dalam batas normal	Dalam batas normal	terlibat furkasi	Terdapat penurunan tulang alveolar sebanyak 0,7 mm pada distal gigi 36, berbentuk segitiga pada mesial sedangkan distal berbentuk trapesium, terdapat tulang kortikal dan tulang kanselus gepeng padat.	radiodensitas lesi: radiopak\nlokasi dan perluasan lesi: pada akar distal dari 1/3 tengah hingga 1/3 apikal gigi 36 \nbentuk dan ukuran diameter lesi: bulat dengan diameter 5 mm\nbatas tepi: tegas dan jelas\t\t\t\t\t\t\nstruktur interna less: radiopak	terdapat kelainan pada mahkota, alveolar dan periapikal	radiodensitas lesi: radiopak\nlokasi dan perluasan lesi: pada akar distal dari 1/3 tengah hingga 1/3 apikal gigi 36 \nbentuk dan ukuran diameter lesi: bulat dengan diameter 5 mm\nbatas tepi: tegas dan jelas\t\t\t\t\t\t\nstruktur interna lesi: radiopak	diagnosis: Hypersementosis\ndd: Cementoblastoma dan Dense bone island	4122023037	Khairunnisa Nabiilah Putri	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
a3730dd7-3f29-4594-b39f-290d9e2de878	01	RKG270524-6007	RKG 1	Ny.Y	Jl. Cempaka Putih	0	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023034	\N	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
c4b6edeb-3510-4b0b-833b-d7ccf7c0f7ef	7	RKG280524-7145	7	RKG 2 : Periapikal 7 : Ny. F	Jl. F	22	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023039	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PERIAPIKAL	\N
4ebd3972-5e7b-4088-af4e-b27af3907f39	8	RKG280524-8860	8	RKG 2 : Panoramik 2 : Tn. G	Jl. G	22	\N	\N	\N	PANORAMIK	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023039	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PANORAMIK	\N
e6efbce6-0959-4bfa-b05a-b4cbfab686e0	9	RKG280524-6704	9	RKG 2 : Periapikal 9 : Tn. H	Jl. H	22	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023039	\N	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PERIAPIKAL	\N
9eae6731-bdaf-451b-b698-29d1b4f9d4b3	11	RKG280524-5411	11	RKG 2 : Video Oklusal	-	22	\N	\N	\N	OKLUSI	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023039	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	OKLUSI	\N
13281771-1d3a-48c2-9e44-bc6aa947b7bd	01	RKG280524-8295	RKG 2	Hani	Jl. Kemanggisan V no. 6	18	2024-05-28	Pulpstone pada gigi 44	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/a829a4bb-60d2-4fe6-a43f-8b1b050bff9f.jpeg	PERIAPIKAL	DBN	Akar tunggal dan lurus, terdapat radiopak pada bagian 1/3 tengah	Melebar pada bagian 1/3 tengah	Melebar pada bagian 1/3 tengah	-	DBN	DBN	Terdapat kelainan pada akar, membran periodontal, dan lamina dura	-	Pulp stone\nDD : dens ivaginatus, sklerosis pulpa	4122023045	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	FINISH	OPEN	PERIAPIKAL	\N
e8e81770-fec3-4d9c-9a95-9b7c38ef0bfa	3	RKG270524-5785	RKG 1	Tn.X/Interpretasi Periapikal 1	RSGM Universitas Andalas, Sumatera Barat	53	2024-05-27	Abfraksi adalah kerusakan di bagian servikal gigi yang disebabkan oleh kekuatan eksternal yang menyebabkan terjadi cekungan yang tajam, biasanya karena pasien mengalami kebiasaan menggigit terlalu keras (bruxism) atau maloklusi (gigi berjejal).	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/25ba40e8-202c-4a52-996a-80dff47c6c09.png	PERIAPIKAL	Dalam batas normal	Pada gigi 45 terdapat satu akar, tunggal	Pada 1/3 tengah dan 1/3 apikal pada mesio lateral menebal dan 1/3 apikal disto lateral menebal	Pada 1/3 servikal, 1/3 tengah dan 1/3 apikal pada mesio lateral dan disto lateral menghilang	tidak ada furkasi	- Terjadi penurunan tulang alveolar pada bagian medial sebesar 0,24 dan bagian distal 0,22 mm\n- berbentuk trapesium pada medial dan distal \n- tulang kortikalnya ada berbentuk gepeng padat	- Radiodensitas lesi: radiolusen \n- lokasi dan perluasan lesi: radiolusen pada 1/3 apikal gigi 45\n- Bentuk dan ukuran diameter lesi: oval dan berdiameter kurang lebih 5 mm\n- Batas tepi: jelas dan tegas \n- Struktur interna lesi: radiolusen\n- efek lesi terhadap jaringan sekitar: tidak ada	terdapat kelainan pada tulang alveolar, periapikal, membran periodontal dan lamina dura.	- Radiodensitas lesi: radiolusen \n- lokasi dan perluasan lesi: radiolusen pada 1/3 apikal gigi 45\n- Bentuk dan ukuran diameter lesi: oval dan berdiameter kurang lebih 5 mm\n- Batas tepi: jelas dan tegas \n- Struktur interna lesi: radiolusen\n- efek lesi terhadap jaringan sekitar: tidak ada	Diagnosis: Abfraksi pada servikal gigi disertai lesi periapikal sesuai dengan gambaran radiograf suspect granuloma\n\ndd: Abfraksi pada servikal gigi disertai lesi periapikal sesuai dengan gambaran radiograf suspect abses	4122023037	Khairunnisa Nabiilah Putri	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
0a098ea9-3b89-479a-a2cf-c635a693a954	4	RKG270524-4688	RKG 1	An.X/Interpretasi Panoramik 1	Rumah Sakit Gigi Universitas Nasional Kyungpook	16	2024-05-27	Cementoblastoma adalah  tumor jinak/ adanya pertumbuhan bahan pembentuk gigi di dekat akar gigi. Tumor ini bermanifestasi sebagai pertumbuhan sementum yang berbentuk bulat yang berkembang di sekitar akar dan apeks akar gigi.\nEtiologi dari cementoblastoma tidak diketahui.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/9a9859f9-2ec0-4470-a1ab-664f705fc8a0.png	PANORAMIK	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023037	Khairunnisa Nabiilah Putri	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	Tidak ada	Tidak ada	Tidak ada	Tidak ada Karena umur pasien 16 tahun gigi masih dalam masa pertumbuhan.	Gigi 11 terdapat gambaran radiopak pada bagian distal gigi, terjadi overlap dengan gigi 12, Gigi 21 terdapat gambaran radiopak pada bagian distal gigi, terjadi overlap dengan gigi 22, Gigi 24 terdapat gambaran radiopak pada bagian mesial gigi, terjadi overlap dengan gigi 23, Gigi 34 terdapat gambaran radiopak pada bagian mesial gigi, terjadi overlap dengan gigi 35, Gigi 44 terdapat gambaran radiopak pada bagian distal gigi, terjadi overlap dengan gigi 45	Dalam batas normal	Dalam batas normal	Terdapat lesi dengan gambaran radiopak dengan batas radiolusen jelas dan tegas pada apikal gigi 46 hingga mesial gigi 47	Dalam batas normal	\N	\N	WRITE	OPEN	PANORAMIK	\N
a26503c4-3d6e-4245-bbf9-7cb4f8f55b38	8	RKG270524-2704	RKG 2	Ny.C/Interpretasi Panoramik Rkg 2	Fakultas Kedokteran Gigi Universitas Sao Paulo-Brazil	31	2024-05-27	Gigi 28 impaksi klasifikasi C posisi vertikal overlap dengan sinus maxilary\nGigi 38 impaksi Class II klasifikasi B posisi distoangular overlap dengan kanalis mandibula	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/285f75f2-27eb-44de-bc92-67382dd4c3d2.png	PANORAMIK	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023037	Khairunnisa Nabiilah Putri	drg. Resky Mustafa,M. Kes.,Sp.RKG	Gigi 18 missing	-	-	Gigi 28 dan 38 impaksi	1.\tGigi 17 terdapat gambaran radiopak pada bagian mesial oklusal gigi  2.\tGigi 16 terdapat gambaran radiopak pada bagian oklusal gigi dari mesial hingga distal  3.\tGigi 13 terdapat gambaran radiopak pada distal gigi, terjadi overlap dengan gigi 14 4.\tGigi 23 terdapat gambaran radiopak pada distal gigi, terjadi overlap dengan gigi 24 5.\tGigi 24 terdapat gambaran radiopak pada distal gigi, terjadi overlap dengan gigi 25 6.\tGigi 26 terdapat gambaran radiopak pada mahkota mesial sampai ke mahkota distal meluas hingga kamar pulpa  7.\tGigi 37 terdapat gambaran radiopak pada oklusal gigi dari mesial sampai ke distal meluas hingga kamar pulpa 8.\tGigi 36 terdapat gambaran radiopak pada mahkota mesial meluas ke distal hingga kamar pulpa  9.\tGigi 34 terdapat gambaran radiopak pada distal gigi, terjadi overlap dengan gigi 35	-\tTerdapat gambaran radiopak pada akar mesial dan distal gigi 26 mencapai 1/3 apikal gigi -\tTerdapat sisa akar gigi 46	Dalam batas normal	Tidak ada	Dalam batas normal	\N	\N	WRITE	OPEN	PANORAMIK	\N
0132331e-66c0-48b2-9b08-a23d4c7c147c	6	RKG270524-3117	RKG 2	Ny.A/Interpretasi Periapikal 2	Mathura, Uttar Pradesh-India	25	2024-05-27	Microdontia merupakan gigi berukuran lebih kecil dari biasanya, mikrodontia dapat melibatkan semua gigi atau terbatas pada satu gigi atau sekelompok gigi. Sering kali pada gigi insisivus lateral  dan gigi molar ketiga berukuran kecil. Peg shapes adalah gigi kecil berbentuk kerucut yang disebabkan oleh kelainan gigi yang disebut mikrodontia atau agenesis gigi (yaitu, gigi memiliki akar yang lebih pendek dari yang diharapkan).	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/43ecef55-248d-4d05-b401-65e4a5b7ff10.png	PERIAPIKAL	Mahkota gigi 31 berbentuk runcing/pasak  (Peg shaped)	1 akar 1 saluran akar	Dalam batas normal	Dalam batas normal	Tidak ada furkasi	Terjadi penurunan 4 mm dari CEJ	Tidak ada	Terdapat kelainan pada mahkota, alveolar crest	Tidak ada	Diagnosis: Microdontia (Peg shapes)\ndd : Supernumerry teeth	4122023037	Khairunnisa Nabiilah Putri	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
36683278-bd1d-498e-9a35-ae6dadb4f9dc	7	RKG270524-6417	RKG 2	An.B/Interpretasi Oklusal Rkg 2	Universitas Indonesia, Jakarta-Indonesia	12	2024-05-27	- Mahkota gigi berada diantara servikal gigi 11 dan mahkota gigi 22  berbatasan dengan foramen incisive dan suture median palatine \n- Akarnya berada di palatine of maxila	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/49512a06-cd52-4b0e-8ea0-12d2d846fc95.png	OKLUSI	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023037	Khairunnisa Nabiilah Putri	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	Radiopak	Unilateral impact incisive gigi 21	WRITE	OPEN	OKLUSI	\N
d1b63a68-3c72-4a7c-aae1-53de542c09ce	01	RKG270524-4986	rkg 1	Tn.x / Periapikal intepretasi rkg 1	Bosnia, Amerika	40	2024-05-27	Supernumerary teeth atau gigi tambahan adalah suatu kelainan di mana jumlah gigi lebih dari normal.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/eb94c0d3-4cdd-4ee3-a77e-718204d581e4.png	PERIAPIKAL	Dalam Batas Normal	Dalam Batas Normal	Dalam Batas Normal	Dalam Batas Normal	-	Dalam Batas Normal	Dalam Batas Normal.	Terdapat gambaran gigi tambahan atau supernumerary teeth pada regio kanan bawah	-	Supernumerary Teeth \nDD: garder syndrome, Pyknodysostosis	4122023025	Amalia Rafa Wulandari	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
a1c7e493-7e77-4b5e-98e4-eccd94fd264a	-	RKG280524-9784	-	An. X	Jl. C	15	\N	\N	\N	PANORAMIK	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023039	\N	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PANORAMIK	\N
673e4ada-95fe-4f08-9940-ec81b8d4e770	-	RKG310524-7044	-	Video Periapikal	Cempaka putih	22	\N	-	\N	PERIAPIKAL	-	-	-	-	-	-	-	-	-	-	4122023032	Ivan Hasan	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	https://drive.google.com/drive/folders/134kxrWkW2I4WStnvHpJLnTbTvpskWhkW?usp=drive_link
db62e1a4-01b4-4be9-99fa-3b82bfbd4e09	05	RKG280524-9917	rkg 1	Nn. P/ periapikal intepretasi rkg 1	Jakarta Barat	24	2024-05-28	peradangan lokal pada jaringan periapikal yang berasal dari penyakit pulpa.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/ced3a848-6f09-4d8f-96fe-0f6682a94232.png	PERIAPIKAL	Terdapat gambaran radiopak tambalan mencapai kamar pulpa pada sisi mesial 1/3 tengah mahkota dengan bayangan radiolusen di sekeliling tambalan tersebut	Dalam Batas Normal	ruang periodontal sisi mesial (lateral dan medial), distal (lateral dan medial): \n                # 1/3 servikal\t\t\t\t\tMelebar\t\tNormal\t\t\t\n\t\t\t\t# 1/3 tengah\t                Normal\t\tNormal\t\t\t\n\t\t\t\t#1/3 apikal\t                    Melebar\t\tMelebar	lamina dura sisi mesial (lateral dan medial), distal (lateral dan medial). : \n# 1/3 servikal\t\t\t\t\tNormal\t\tMenipis\t\t\t\n#1/3 tengah\t                   Menebal\t\tNormal\t\t\t\n#1/3 apikal\t                   Terputus\t\tTerputus	-	alveolar crest\t\t\t\t\tMesial\t\t                                                                                 Distal\t\t\t\ni. tinggi\t\t\t\t\t1 mm dari CEJ\t                                                 \t0,5 mm dari CEJ\t\t\t\nii.bentuk\t\t\t\t\tMengalami penumpulan dalam arah horizontal\t\tMengalami penumpulan dalam arah horizontal\t\t\t\niii.tulang kortikal :\t\tAda\t\t                                                              Ada\t\t\t\n\t# kontinuitas\t\t\tKontinu\t\t                                                      Kontinu\t\t\t\n\t# outline\t\t\t\t    Ireguler\t\t                                                      Ireguler\t\t\t\n\t# tebal/lebar\t\t\tNormal\t\t                                                      Normal\t\t\t\n\t# densitas\t\t\t\tNormal\t\t                                                      Normal	radiodensitas lesi\t\t\t\t            \tRadiolusen\t\t\t\t\t\t\t\nlokasi dan perluasan lesi\t\t\t\t\tBerada di 1/3 apikal akar gigi 12\t\t\t\t\t\t\t\nbentuk dan ukuran diameter lesi\t\tBulat dengan diameter 4 mm\t\t\t\t\t\t\t\nbatas tepi\t\t\t\t\t                       Jelas\t\t\t\t\t\t\t\nstruktur interna lesi\t\t\t\t            \tRadiolusen\t\t\t\t\t\t\t\nefek lesi terhadap jaringan sekitar\t\tLesi menyebabkan peningkatan densitas tulang pada sekitarnya	Terdapat gambaran radiolusen pada 1/3 apikal gigi 12	lokasi dan perluasan lesi\t\t\t\t\tBerada di 1/3 apikal akar gigi 12\t\t\t\t\t\t\t\nbentuk dan ukuran diameter lesi\t\tBulat dengan diameter 4 mm\t\t\t\t\t\t\t\nbatas tepi\t\t\t\t\t                       Jelas\t\t\t\t\t\t\t\nstruktur interna lesi\t\t\t\t            \tRadiolusen\t\t\t\t\t\t\t\nefek lesi terhadap jaringan sekitar\t\tLesi menyebabkan peningkatan densitas tulang pada sekitarnya	Periodontitis apikalis kronis disertai dengan mild chronic localized periodontitis\t\t\t\t\t\t\t\n\ndd: Granuloma periapikal disertai dengan mild chronic localized periodontitis	4122023025	Amalia Rafa Wulandari	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
c6ff49a2-9568-4b1b-abd6-5705d2adb238	06	RKG280524-1846	rkg 1	Tn. K/ Panoramic Intepretasi	Korea Selatan	17	\N	Cementoblastoma adalah proliferasi sementoblas yang bersifat hamartomatous, membentuk sementum yang tidak teratur di sekitar setengah apikal akar gigi.	\N	PANORAMIK	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023025	Amalia Rafa Wulandari	drg. Resky Mustafa,M. Kes.,Sp.RKG	-	-	-	-	Gigi 11 terdapat gambaran radiopak pada bagian distal gigi, terjadi overlap dengan gigi 12 Gigi 21 terdapat gambaran radiopak pada bagian distal gigi, terjadi overlap dengan gigi 22 Gigi 24 terdapat gambaran radiopak pada bagian mesial gigi, terjadi overlap dengan gigi 23 Gigi 34 terdapat gambaran radiopak pada bagian mesial gigi, terjadi overlap dengan gigi 35 Gigi 44 terdapat gambaran radiopak pada bagian distal gigi, terjadi overlap dengan 45 Gigi 34 terdapat radiolusen pada dentin	dalam batas normal	dalam batas normal	Terdapat lesi dengan gambaran radiopak dengan batas radiolusen jelas pada 1/3 apikal gigi 46 hingga 1/3 apikal mesial gigi 47	dalam batas normal	\N	\N	WRITE	OPEN	PANORAMIK	\N
eea265f3-4fab-497a-bc18-44dafbe6ebdd	04	RKG280524-5313	RKG 1	Ny. X	Jakarta	0	2024-05-28	-\tGigi 16 tambalan mencapai dentin\n-\tGigi 16 ekstrusi\n-\tGigi 13 atrisi\n-\tGigi 23 tambalan servikal \n-\tGigi 12 tambalan mencapai dentin\n-\tGigi 21 restorasi crown mencapai kamar pulpa\n-\tGigi 22 karies mencapai dentin\n-\tGigi 23 tambalan mencapai email\n-\tGigi 24 tambalan pada servikal\n-\tGigi 27 tambalan mencapai dentin\n-\tGigi 47 tambalan mencapai dentin\n-\tMild dan moderate periodontitis generalis dengan stage 1 dan 2 grade B	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/0e463256-432b-4ecf-8f7b-ac2705215961.png	PANORAMIK	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023024	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	-	-	-	-	1.\tGigi 16 terdapat gambaran radiopak pada distal dari email hingga dentin, 3.\tGigi 12 terdapat gambaran radiopak pada distal dari email hingga dentin, 4.\tGigi 21 terdapat gambaran radiopak pada mahkota dari email hingga kamar pulpa (restorasi crown), 5.\tGigi 22 gambaran radiolusen distal mahkota pada email hingga kamar pulpa, 6.\tGigi 23 terdapat gambaran radiopak pada email, 7.\tGigi 24 terdapat gambaran radiopak pada servikal, 8.\tGigi 27 terdapat gambaran radiopak pada email hingga dentin, 10.\tGigi 47 terdapat gambaran radiopak pada oklusal dari email hingga dentin	\N	Terjadi penurunan tulang sebanyak +/- 4-5 mm	DBN	DBN	\N	\N	WRITE	OPEN	PANORAMIK	-
f74cb418-8ec3-400d-866c-5bb80f29b739	01	RKG280524-9266	RKG 1	Ny. X/ Periapikal/ drg. Resky	Jl. X	0	2024-05-28	Moderate periodontitis stage II dan fraktur gigi menurut klasifikasi ellis dan davey kelas I\nDD : moderate periodontitis stage II dan fraktur gigi menurut klasifikasi ellis dan davey kelas II	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/6dfbecd5-3280-4da5-8818-d8500a29c0dd.jpeg	PERIAPIKAL	gigi 11 : terdapat radiolusen di sebelah distal, ukuran mesial distal mahkota 0,5 mm terdapat radiopak dari mesial hingga distal di bagian tengah yaitu bracket dan wire	gigi 11 : terdapat satu akar atau akar tunggal dan satu saluran akar	terputus dari 1/3 servikal hingga 1/3 tengah pada bagian mesio lateral, mesio medial, disto lateral \nmelebar pada bagian 1/3 apikal pada bagian mesio lateral, mesio medial, disto lateral	terputus : bagian mesio lateral, mesio medial, disto lateral (1/3 servikal). \nmelebar : bagian mesio lateral, mesio medial, disto lateral (1/3 tengah). \ndalam batas normal : mesio lateral, mesio medial, disto lateral (1/3 apikal).	tidak ada	mesial : jarak dari CEJ 3,3 mm dan penurunan 1,3 mm \ndistal : jarak dari CEJ 2,6 mm dan penurunan 0,6 mm	tidak ada	terdapat kelainan pada mahkota dan alveolar crest	tidak ada	moderate periodontitis stage II dan fraktur gigi menurut klasifikasi ellis dan davey kelas I\nDD : moderate periodontitis stage II dan fraktur gigi menurut klasifikasi ellis dan davey kelas II	4122023033	Ivo Resky Primigo	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
85190ec8-a85d-4642-b1ad-32635a4dfa2e	07	RKG280524-9347	rkg 2	Nn. B/ periapikal intepretasi	Jakarta	23	2024-05-28	Periodontitis agresif merupakan penyakit periodontitis yang laju perkembangan dan kerusakannya terjadi sangat cepat	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/3960f47e-3297-4c66-ba42-f6683d14efe3.png	PERIAPIKAL	Terdapat gambaran radiopak tambalan dari email hingga dentin	terdapat 2 saluran akar dalam batas normal	ruang periodontal sisi mesial (lateral dan medial), distal (lateral dan medial): \n# 1/3 servikal\t\t\t\t\tmenebal\t\tmenebal\t\t\t\n# 1/3 tengah\t                menebal\t\tmenebal\t\t\t\n#1/3 apikal\t                    menebal\t\tmenebal	lamina dura sisi mesial (lateral dan medial), distal (lateral dan medial). : \n# 1/3 servikal\t\t\t\t\tmenebal\t\t           menebal\t\t\t\n#1/3 tengah\t                   menebal\t\t           menebal\t\t\t\n#1/3 apikal\t                   menebal\t\t           menebal	Ada	alveolar crest\t\t\t\t\tMesial\t\t                            Distal\t\t\t\ni. tinggi\t\t\t\t\tpenurunan sebesar 6ml\t\tpenurunan sebesar 6ml\t\t\t\nii.bentuk\t\t\t\t\ttrapesium\t\t                   segitiga \t\t\t\niii.tulang kortikal :\tada\t\t                              ada\t\t\t\n\t# kontinuitas\t   kontinue\t\t                      Kontinue \t\t\t\n\t# outline\t\t\t   Regular\t\t                      Regular\t\t\t\n\t# tebal/lebar\t   lebar\t\t                              lebar\t\t\t\n\t# densitas\t\t   normal\t\t                          normal\t\t\t\niv.tulang kanselus (spongious) : -densitas\t\t\t\t\tpadat\t\tpadat\t\t\t\n                                                  -pola\t\t\t\t\tgepeng\t\tgepeng	dalam batas normal	tulang alveolar pada mesiolateral terjadi penurunan 6 mm dari CEJ dan pada distolateral terjadi penurunan 6 ml dari CEJ\t\t\t\t\t\nalveolar crest: Mengalami penumpulan dalam arah horizontal	-	Localized Aggressive Periodontitis dengan penurunan tulang 1/3 tengah di sisi distal dan mesial \t\t\t\t\t\t\t\n\ndd: Moderate chronic periodontitis dengan penurunan tulang 1/3 tengah di sisi distal dan mesial	4122023025	Amalia Rafa Wulandari	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
3d822f50-f7d7-4c97-8da2-6252be730349	1	RKG280524-1310	1	RKG 1: Periapikal 1 : Tn. A	Jl. A	22	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023039	\N	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PERIAPIKAL	\N
0605926f-7e99-4de9-9825-aa8d15900618	03	RKG280524-9613	RKG 1	Viola	Jl. Venus Raya blok A/4	23	2024-05-28	Karies mencapai dentin	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/dab4cf6c-c447-4c20-bba5-4dca723654d3.jpeg	PERIAPIKAL	Terdapat gambaran radiolusen berupa karies dari mahkota hingga dentin pada bagian mesial	Terlihat 2 akar dan 2 saluran akar	Pada mesial : membran periodontal melebar\nPada distal : membran periodontal melebar	Pada mesial \n1/3 tengah melebar \n1/3 apikal terputus\n\nPada distal\n1/3 servikal terputus\n1/3 tengah melebar	DBN	Pada mesial tidak dapat dievaluasi. Pada distal alv crest berbentuk horizontal dan jarak dari CEJ ke alv crest 0,6 mm	DBN	terdapat kelainan pada mahkota, membran, lamina dura, alv crest	-	Karies mencapai dentin\n\nDD: Karies mencapai pulpa	4122023045	Shabrina Ghisani	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	FINISH	OPEN	PERIAPIKAL	\N
9312aac4-610f-4538-a9ce-3a14d3990dbe	-	RKG280524-4618	-	Periapikal 1	-	0	2024-05-28	-	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/e85cc4ac-6942-46f8-a786-1d304669b745.png	PERIAPIKAL	--	--	-	-	-	-	-	-	-	-	4122023032	Ivan	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
151f19fd-7804-4446-9811-865612aefbb0	04	RKG280524-6416	RKG 2	Tn X	Jl. Cempaka baru No. 6	0	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023045	\N	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PERIAPIKAL	\N
fe844e7a-8ddb-415d-aca8-afc678237c99	001	RKG280524-5692	RKG 1	NY. AB	jl. Cempaka Putih	0	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023034	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
662debb6-4a69-4861-a734-8f833937d594	-	RKG280524-5401	RKG 1	NY. BA	jl. kalimalang	0	\N	\N	\N	PERIAPIKAL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023034	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
af75baa0-0a13-437e-91a2-f73aef06a545	01	RKG280524-6394	RKG 2	Nn. Y	Tangerang	0	2024-05-28	periapical cemento osseous dysplasia adalah lesi jinak yang jarang terjadi, sering kali tanpa gejala, di mana jaringan fibrosa menggantikan jaringan tulang normal.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/b75ef565-2b07-4352-af81-694c06649d4b.png	PERIAPIKAL	DBN	terlihat 1 akar dan 1 saluran akar, terdapat gambaran radiopak dikelilingi oleh radiolusen di 1/3 akar	Pada 1/3 tengah menghilang dan menebal pada 1/3 servikal	Pada 1/3 tengah menghilang dan menebal pada 1/3 servikal	-	mengalami penurunan 4 mm dari CEJ dan berbentuk trapezoid	Terdapat lesi dengan gambaran:\nradiodensitas lesi: Radiopak dikelilingi oleh radiolusen pada 1/3 apikal\t\t\t\t\t\t\t\nlokasi dan perluasan lesi: 1/3 apikal  gigi 31 meluas hingga ke distal gigi \t\t\t\t\t\t\t\nbentuk dan ukuran diameter lesi: asimetri dan berdiameter +/- 4-5 mm\t\t\t\t\t\t\t\nbatas tepi: tidak jelas dan tidak tegas\t\t\t\t\t\t\t\nstruktur interna lesi: Radiopak dikelilingi radiolusen\t\t\t\t\t\t\t\nefek lesi terhadap jaringan sekitar: Lesi menyebabkan pembesaran tulang alveolar	Terdapat kelainan di periapikal, alveolar, membran periodontal, lamina dura	radiodensitas lesi: Radiopak dikelilingi oleh radiolusen pada 1/3 apikal\t\t\t\t\t\t\t\nlokasi dan perluasan lesi: 1/3 apikal  gigi 31 meluas hingga ke distal gigi \t\t\t\t\t\t\t\nbentuk dan ukuran diameter lesi: asimetri dan berdiameter +/- 4-5 mm\t\t\t\t\t\t\t\nbatas tepi: tidak jelas dan tidak tegas\t\t\t\t\t\t\t\nstruktur interna lesi: Radiopak dikelilingi radiolusen\t\t\t\t\t\t\t\nefek lesi terhadap jaringan sekitar: Lesi menyebabkan pembesaran tulang alveolar	periapical cemento osseous dysplasia disertai localized periodontitis stage 1 grade b (suspect radiodiagnosis: early localized periodontitis)\t\t\t\t\t\t\t\nDD: rarefying osteitis disertai dengan localized periodontitis stage 2 grade b  (suspect radiodiagnosis: moderate localized periodontitis)\t\t\t\t\t\t\t\nDD: cementoblastoma disertai localized periodontitis stage 2 grade b  (suspect radiodiagnosis: moderate localized periodontitis)	4122023024	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	-
1231e063-7355-4950-b496-4ec72aede919	02	RKG280524-1605	RKG 2	Nn. x	Indonesia	29	2024-05-28	Karies mencapai pulpa disertai disertai localized periodontitis stage 1 grade b disertai dengan suspect radiodiagnosis periodontitis apikalis kronis	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/2be6ac2e-464e-4489-b113-5396cd75c6c3.png	PERIAPIKAL	Terdapat gambaran radiopak pada mahkota bagian insisal dari email hingga kamar pulpa dan radiolusen pada mesial dari email hingga dentin	Terdapat 1 akar dan 1 saluran akar	Menebal pada 1/3 apikal	Menebal pada 1/3 apikal	-	penurunan 4 mm dari CEJ	Terdapat gambaran Lesi pada gigi 12\nradiodensitas lesi: radiolusen\t\t\t\t\t\t\t\nlokasi dan perluasan lesi: 1/3 apikal gigi 12\t\t\t\t\t\t\t\nbentuk dan ukuran diameter lesi: oval beraturan dan berdiameter +/- 1-2 mm\t\t\t\t\t\t\t\nbatas tepi: tidak jelas dan tidak tegas\t\t\t\t\t\t\t\nstruktur interna lesi: radiolusen	Terdapat kelainan pada mahkota, periapikal, lamina dura, membran periodontal, tulang alveolar	Lesi gigi 12\nradiodensitas lesi: radiolusen\t\t\t\t\t\t\t\nlokasi dan perluasan lesi: 1/3 apikal gigi 12\t\t\t\t\t\t\t\nbentuk dan ukuran diameter lesi: oval beraturan dan berdiameter +/- 1-2 mm\t\t\t\t\t\t\t\nbatas tepi: tidak jelas dan tidak tegas\t\t\t\t\t\t\t\nstruktur interna lesi: radiolusen	Karies mencapai pulpa disertai disertai localized periodontitis stage 1 grade b disertai dengan suspect radiodiagnosis periodontitis apikalis kronis\t\t\t\t\t\t\t\nDD; Karies mencapai dentin disertai dengan localized periodontitis stage 2 grade b disertai dengan suspect radiodiagnosis abses dini\t\t\t\t\t\t\t\nDD; Karies mencapai dentin disertai localized periodontitis stage 2 grade b disertai dengan suspect radiodiagnosis granuloma periapical	4122023024	Adila Hikmayanti	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	WRITE	OPEN	PERIAPIKAL	\N
be56c015-820e-4faa-a553-c1e482809ee9	03	RKG280524-7796	RKG 2	Tn. J	Korea	21	2024-05-28	Enamel pearls atau enameloma adalah formasi kecil email dengan diameter 1 sampai 3 mm yang terdapat pada akar gigi geraham.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/06840fdf-a180-46f5-8f3e-3fc6aaee3af4.png	PERIAPIKAL	Terdapat gambaran radiopak  di mesio  oklusal dari email sampai dentin	Terdapat 3 akar dan 2 saluran akar. Terdapat 2 gambaran ovoid pada saluran akar distal dan mesial di 1/3 servikal.	DBN	DBN	DBN	DBN	DBN	Terdapat kelainan pada mahkota dan akar	-	Enamel pearls\nDD: Pulp stones\nDD: Dens invaginatus	4122023024	Adila Hikmayanti	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OPEN	OPEN	PERIAPIKAL	\N
6c621edd-171e-476c-8a14-c960bf2ca13a	04	RKG280524-8549	RKG 2	Ny. Z	Japan	24	2024-05-28	Osteoid osteoma  adalah neoplasma jinak osteoblas tanpa adanya potensi metastatis yang mirip dengan osteoblastoma.	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/8e6130ec-f773-4227-87e4-c8f0258f2a3c.png	PANORAMIK	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023024	Adila Hikmayanti	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	-	-	-	-	Overlap 16, 15, 24, 25, 26, 35, 36, dan 45	DBN	DBN	Terdapat gambaran radiolusen pada apikal gigi 47	DBN	\N	\N	WRITE	OPEN	PANORAMIK	-
7bb39c62-3e39-45c5-95da-5c07d927f596	05	RKG280524-5367	RKG 2	Tn. SJ	Australia	12	2024-05-28	Mahkota Gigi 13 berada antara apikal gigi 11, 12, dan 14 berbatasan dengan foramen insisiv dan sutura intermaksilaris\nAkar gigi 13 overlapping pada palatal gigi 14, 15, dan 16 berbatasan dengan nasal septum\nMahkota Gigi 23 berada antara apikal gigi 21, 22, dan 24\nAkar gigi 23 overlapping dengan palatal gigi 25 sampai 26	https://rsuyarsibucket.s3.ap-southeast-1.amazonaws.com/emr/radiologi/ee6b1da7-d043-42bc-a13b-2e339bb989cf.png	OKLUSI	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023024	\N	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	Kelainan lokasi gigi 13 dan 23	Bilateral maksila impacted caninus (13 dan 23) class 2	WRITE	OPEN	OKLUSI	\N
a15b8121-841b-4a03-a67c-b2ce12d30c83	-	RKG300524-9652	-	Video oklusal	Cempaka putih	22	\N	-	\N	OKLUSI	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4122023032	Ivan Hasan	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N	\N	\N	\N	\N	\N	\N	\N	\N	-	-	WRITE	OPEN	OKLUSI	https://drive.google.com/drive/folders/1agyr5x4FdtzbkDOcJNamHwai2XHTdYl4?usp=drive_link
\.


--
-- TOC entry 3722 (class 0 OID 16506)
-- Dependencies: 230
-- Data for Name: failed_jobs; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.failed_jobs (id, uuid, connection, queue, payload, exception, failed_at) FROM stdin;
\.


--
-- TOC entry 3724 (class 0 OID 16513)
-- Dependencies: 232
-- Data for Name: finalassesment_konservasis; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.finalassesment_konservasis (uuid, nim, name, kelompok, tumpatan_komposisi_1, tumpatan_komposisi_2, tumpatan_komposisi_3, tumpatan_komposisi_4, tumpatan_komposisi_5, totalakhir, grade, keterangan_grade, yearid, semesterid, studentid) FROM stdin;
2d10535a-7709-45fd-8baf-76c10870c9fb	4122023034	Jessica Putri Souisa		21.6	23.75	15.6	2	0	62.95	B-		04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	12a16ac8-2655-4f67-b69f-3615d5054a13
\.


--
-- TOC entry 3725 (class 0 OID 16519)
-- Dependencies: 233
-- Data for Name: finalassesment_orthodonties; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.finalassesment_orthodonties (id, nim, name, kelompok, anamnesis, foto_oi, cetak_rahang, modelstudi_one, analisissefalometri, fotografi_oral, rencana_perawatan, insersi_alat, aktivasi_alat, kontrol, model_studi_2, penilaian_hasil_perawatan, laporan_khusus, totalakhir, grade, keterangan_grade, nilaipekerjaanklinik, nilailaporankasus, analisismodel, yearid, semesterid, studentid) FROM stdin;
74116f3a-2465-4d87-9aeb-28126b0249e9	4122023045	Shabrina Ghisani M		2.48	4.48	0	6.12	9.6	2.16	6.4	4.2	5.11	0	3.5	0	4	51.35	CD		44.9825000000000000	0.20000000000000000000	3.3	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	254fbe52-438a-4e69-963c-1103a4482b51
\.


--
-- TOC entry 3726 (class 0 OID 16525)
-- Dependencies: 234
-- Data for Name: finalassesment_periodonties; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.finalassesment_periodonties (id, nim, name, kelompok, anamnesis_scalingmanual, anamnesis_uss, uss_desensitisasi, splinting_fiber, diskusi_tatapmuka, dops, totalakhir, grade, keterangan_grade, yearid, semesterid, studentid) FROM stdin;
b288ff18-8418-4059-815f-454115a19b29	4122023030	Faika Zahra Chairunnisa		42.69	0	0	0	0	0	42.69	D		04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	c6df72a6-1070-48d7-9342-ec799bf9f5b1
\.


--
-- TOC entry 3727 (class 0 OID 16531)
-- Dependencies: 235
-- Data for Name: finalassesment_prostodonties; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.finalassesment_prostodonties (id, nim, name, kelompok, penyajian_diskusi, gigi_tiruan_lepas, dops_fungsional, totalakhir, grade, keterangan_grade, yearid, semesterid, studentid) FROM stdin;
\.


--
-- TOC entry 3728 (class 0 OID 16537)
-- Dependencies: 236
-- Data for Name: finalassesment_radiologies; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.finalassesment_radiologies (uuid, nim, name, kelompok, videoteknikradiografi_periapikalbisektris, videoteknikradiografi_oklusal, interpretasi_foto_periapikal, interpretasi_foto_panoramik, interpretasi_foto_oklusal, rujukan_medik, penyaji_jr, dops, ujian_bagian, totalakhir, grade, keterangan_grade, yearid, semesterid, studentid) FROM stdin;
0f9c721a-df5e-49b8-ad66-2eddf3398f9e	4122023041	Qanita Regina Maharani		0	0	4.95	0	0	0	0	0	0	4.95	E		04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	a9c3e3af-a31e-4ab0-be8d-f7035c065805
4be30a8a-bb9f-4b45-a9b7-2b327feeb299	4122023042	Rayyen Alfian Juneanro		0	0	0	0	0	0	0	0	0	0	\N		04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	e3e7432f-6de7-45fd-b779-710c48a16575
\.


--
-- TOC entry 3729 (class 0 OID 16543)
-- Dependencies: 237
-- Data for Name: hospitals; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.hospitals (id, name, active, created_at, updated_at) FROM stdin;
ee649d27-5ef2-4a00-94e9-d0742c3630ff	RSGM YARSI	1	\N	2024-02-22 12:58:30
f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	RSU YARSI	1	\N	2024-03-18 20:31:08
\.


--
-- TOC entry 3730 (class 0 OID 16547)
-- Dependencies: 238
-- Data for Name: lectures; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.lectures (id, specialistid, name, doctotidsimrs, active, created_at, updated_at, nim) FROM stdin;
2eab15ef-fa97-45ce-a575-cd06a5bbea8d	4b5ca39c-5a37-46d1-8198-3fe2202775a2	drg. Anugrah Prayudi Raharjo	2387	1	\N	\N	D015
ffca59ca-cf49-4c09-82dc-96770ac0bf78	4b5ca39c-5a37-46d1-8198-3fe2202775a2	drg. Selli Reviona	2386	1	\N	\N	D014
a8a87927-17f3-44fc-9867-0acf2cf0881a	4b5ca39c-5a37-46d1-8198-3fe2202775a2	drg. Ufo Pramigi	3831	1	\N	\N	DY169
7d02dd7e-3828-4576-9974-95e01c8af40b	88e2a725-abb3-459d-99dc-69a43a39d504	drg. Yulia Rachma wijayanti, Sp.Perio,MM	3838	1	\N	\N	DY177
9fdbc56a-a5d2-4e6b-bd83-7b85e4830473	a89710d5-0c4c-4823-9932-18ce001d71a5	drg. Bimo Rintoko, Sp.Pros	3859	1	\N	\N	DY233
8af4f325-7be0-4bc0-ac07-851d2543c878	cf504bf3-803c-432c-afe1-d718824359d5	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	3887	1	\N	\N	DY287
b27351d9-1bf2-489a-be00-530575b27cdb	cf504bf3-803c-432c-afe1-d718824359d5	drg. Resky Mustafa,M. Kes.,Sp.RKG	3892	1	\N	\N	DY296
9971c081-ebd7-4980-a5df-af1208046f26	4b5ca39c-5a37-46d1-8198-3fe2202775a2	drg. Vika Novia Zamri, Sp.Ort	2478	1	\N	\N	D106
c71612da-4cd7-4923-babc-c602bc846584	add71909-11e5-4adb-ab6e-919444d4aab7	drg. Hesti Witasari Jos Erry, Sp.KG	3888	1	\N	2024-03-20 15:17:18	DY286
0aad813b-77f2-409b-9fbc-2dc465e5f909	add71909-11e5-4adb-ab6e-919444d4aab7	drg. Chaira Musytaka Sukma, Sp.KG	3836	1	\N	\N	DY172
c5281a78-1a04-4ba7-865e-bccc367f4844	add71909-11e5-4adb-ab6e-919444d4aab7	drg. Dudik Winarko, Sp.KG	3886	1	\N	\N	DY285
414ca7b8-a85d-4c36-b094-de815fccbef0	5756d1b9-34b4-4d49-b5fb-76b68bbd736e	drg. Indira Chairulina Dara, Sp.KGA	3885	1	\N	\N	DY284
\.


--
-- TOC entry 3731 (class 0 OID 16550)
-- Dependencies: 239
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.migrations (id, migration, batch) FROM stdin;
1	2014_10_12_000000_create_users_table	1
2	2014_10_12_100000_create_password_resets_table	1
3	2019_08_19_000000_create_failed_jobs_table	1
4	2019_12_14_000001_create_personal_access_tokens_table	1
5	2024_02_05_070332_create_years_table	1
6	2024_02_05_070551_create_semesters_table	1
7	2024_02_05_070613_create_specialistgroups_table	1
8	2024_02_05_070627_create_specialists_table	1
9	2024_02_05_070659_create_assesmentgroups_table	1
10	2024_02_05_070733_create_assesmentdetails_table	1
11	2024_02_05_070749_create_lectures_table	1
12	2024_02_05_070808_create_students_table	1
13	2024_02_05_070827_create_trsassesments_table	1
14	2024_02_05_070843_create_type_one_trsdetailassesments_table	1
15	2024_02_08_093538_create_hospitals_table	1
16	2024_02_08_093601_create_universities_table	1
17	2024_02_09_052122_create_type_two_trsdetailassesments_table	1
18	2024_02_09_052150_create_type_three_trsdetailassesments_table	1
19	2024_02_09_052507_create_type_four_trsdetailassesments_table	1
20	2024_02_09_052519_create_type_five_trsdetailassesments_table	1
\.


--
-- TOC entry 3733 (class 0 OID 16554)
-- Dependencies: 241
-- Data for Name: password_resets; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.password_resets (email, token, created_at) FROM stdin;
\.


--
-- TOC entry 3734 (class 0 OID 16559)
-- Dependencies: 242
-- Data for Name: patients; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.patients (noepisode, noregistrasi, nomr, patientname, namajaminan, noantrianall, gander, date_of_birth, address, idunit, visit_date, namaunit, iddokter, namadokter, patienttype, statusid, created_at) FROM stdin;
OP066705-200324-0117	RJJP200324-0451	06-67-05	ONG KU AN, TN	KEPANITERAAN FKG	DU-36	M	1971-09-21	JL. GG TOYIB NO. 1A	137	2024-03-20 13:07:00	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP001702-040424-0022	RJJP040424-0193	00-17-02	TESTER30	KEPANITERAAN FKG	BR-13	F	1987-01-01		60	2024-04-04 08:26:38	Poli Gigi Spesialis Prostodonti	3859	drg. Bimo Rintoko, Sp.Pros	PERUSAHAAN	0	\N
OP071756-200324-0114	RJJP200324-0448	07-17-56	JANUAR BASTIAN MAKATUTU	KEPANITERAAN FKG	DU-35	M	1991-01-12	JL PERCETAKAN NEGARA X	137	2024-03-20 13:05:22	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	0	\N
OP074808-200324-0090	RJJP200324-0424	07-48-08	ANGGI PRASETYO	KEPANITERAAN FKG	DU-34	M	1993-07-10	JL. BATU	137	2024-03-20 12:30:14	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP073617-200324-0133	RJJP200324-0392	07-36-17	MUNANIK, NY	KEPANITERAAN FKG	SQ-31	F	1970-03-06	KP BULU RT. 4 RW. 10	137	2024-03-20 11:43:51	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP075180-200324-0087	RJJP200324-0369	07-51-80	YOEL GRACIO BANI	KEPANITERAAN FKG	GY-21	M	2000-01-27	GRAHA CATANIA BLOK U.34 NO.10	59	2024-03-20 11:07:25	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073195-200324-0091	RJJP200324-0301	07-31-95	FAIKA ZAHRA CHAIRUNISA, NN	KEPANITERAAN FKG	SQ-29	F	2002-07-09	JL SPG VII	137	2024-03-20 09:58:49	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP074096-200324-0061	RJJP200324-0195	07-40-96	DODY PRIBADI, TN	KEPANITERAAN FKG	HE-45	M	1981-03-10	JL CIBUBUR 7 GG MANGGA DUA	137	2024-03-20 09:01:53	Poli Gigi Spesialis Konservasi/Endodonsi	3888	drg. Hesti Witasari Jos Erry, Sp.KG	PERUSAHAAN	0	\N
OP074181-200324-0024	RJJP200324-0143	07-41-81	AGNES SUKARSIH, NY	KEPANITERAAN FKG	SQ-28	F	1960-07-27	JL. ANGIN SEJUK IV NO. 31	137	2024-03-20 08:22:17	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP074560-200324-0013	RJJP200324-0126	07-45-60	AISYAH NURAILAH, AN	KEPANITERAAN FKG	VI-10	F	2018-06-22	JL. 25 DUREN SAWIT	58	2024-03-20 08:09:35	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	4	\N
OP075216-200324-0249	RJUL200324-0034	07-52-16	NADIA AUDINA	KEPANITERAAN FKG	SB-11	F	2002-12-28	KP. SADANG	137	2024-03-20 18:07:01	Poli Gigi Spesialis Konservasi/Endodonsi	3888	drg. Hesti Witasari Jos Erry, Sp.KG	PERUSAHAAN	0	\N
OP071756-270324-0019	RJJP270324-0516	07-17-56	JANUAR BASTIAN MAKATUTU	KEPANITERAAN FKG	DU-31	M	1991-01-12	JL PERCETAKAN NEGARA X	137	2024-03-27 13:29:16	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	0	\N
OP075572-270324-0533	RJJP270324-0467	07-55-72	ATIKA RAHMA MINABARI, NY	KEPANITERAAN FKG	SQ-30	F	2000-12-18	JL CENDRAWASIH NO. 99	137	2024-03-27 12:39:18	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	0	\N
OP075731-270324-0529	RJJP270324-0339	07-57-31	CECELIA SANDRA BAYANUDIN, NY	KEPANITERAAN FKG	VN-2	F	2001-04-23	NAGARAKASIH	46	2024-03-27 10:08:10	Poli Gigi Spesialis Orthodonty	2478	drg. Vika Novia Zamri, Sp.Ort	PERUSAHAAN	0	\N
OP075261-270324-0431	RJJP270324-0237	07-52-61	REZZA ZAKI MAULANA, AN	KEPANITERAAN FKG	VI-15	M	2015-03-25	KP BEND MELAYU	58	2024-03-27 09:00:57	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP074560-270324-0377	RJJP270324-0171	07-45-60	AISYAH NURAILAH, AN	KEPANITERAAN FKG	VI-13	F	2018-06-22	JL. 25 DUREN SAWIT	58	2024-03-27 08:15:43	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP073957-270324-0540	RJJP270324-0546	07-39-57	PRADNYA FAIZATUZIHAN AZKIA, NN	KEPANITERAAN FKG	DU-32	F	2002-04-09	TEMBALANG PESONA ASRI L-17	137	2024-03-27 13:48:03	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	0	\N
OP075216-270324-0233	RJJP270324-0586	07-52-16	NADIA AUDINA, NN	KEPANITERAAN FKG	HE-39	F	2002-12-28	KP. SADANG	137	2024-03-27 14:15:14	Poli Gigi Spesialis Konservasi/Endodonsi	3888	drg. Hesti Witasari Jos Erry, Sp.KG	PERUSAHAAN	0	\N
OP071328-270324-0040	RJJP270324-0633	07-13-28	MARLINA BINTI MARTO ,NY	KEPANITERAAN FKG	DU-33	F	1979-03-14	JL SALEMBA TENGAH	137	2024-03-27 14:50:28	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	0	\N
OP075082-280324-0417	RJJP280324-0177	07-50-82	ZIVANA AURELIA AZZAINO, AN	KEPANITERAAN FKG	VI-12	F	2018-04-23	PERUM HARAPAN BARU 1	58	2024-03-28 08:10:46	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP074648-280324-0413	RJJP280324-0140	07-46-48	MUHAMMAD RIZAL, AN	KEPANITERAAN FKG	VI-11	M	2016-01-30	JL. CEMPAKA PUTIH TIMUR	58	2024-03-28 07:51:50	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP075261-020424-0071	RJJP020424-0363	07-52-61	REZZA ZAKI MAULANA, AN	KEPANITERAAN FKG	VI-12	M	2015-03-25	KP BEND MELAYU	58	2024-04-02 10:06:06	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP076102-020424-0522	RJJP020424-0261	07-61-02	MUHAMMAD FATHIR ATTALLAH, AN	KEPANITERAAN FKG	VI-10	M	2014-10-09	JL. KEMUNING 4 B	58	2024-04-02 09:09:19	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP075082-030424-0002	RJJP030424-0204	07-50-82	ZIVANA AURELIA AZZAINO, AN	KEPANITERAAN FKG	VI-12	F	2018-04-23	PERUM HARAPAN BARU 1	58	2024-04-03 09:04:30	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP076102-030424-0149	RJJP030424-0246	07-61-02	MUHAMMAD FATHIR ATTALLAH, AN	KEPANITERAAN FKG	VI-13	M	2014-10-09	JL. KEMUNING 4 B	58	2024-04-03 09:36:28	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP073957-030424-0546	RJJP030424-0306	07-39-57	PRADNYA FAIZATUZIHAN AZKIA, NN	KEPANITERAAN FKG	DU-53	F	2002-04-09	TEMBALANG PESONA ASRI L-17	137	2024-04-03 10:13:22	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	0	\N
OP074083-030424-0010	RJJP030424-0364	07-40-83	JIHAN AR ROHIM, NY	KEPANITERAAN FKG	GY-36	F	2002-06-30	JL. BINTARA RAYA AA 99/4	59	2024-04-03 11:38:41	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP073108-030424-0009	RJJP030424-0363	07-31-08	SAHRI MUHAMAD RIZKY, TN 	KEPANITERAAN FKG	GY-35	M	2000-07-18	JL AK GANI 	59	2024-04-03 11:37:28	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP075642-040424-0043	RJJP040424-0223	07-56-42	ALFAT FADILAH NUR, TN	KEPANITERAAN FKG	SQ-29	M	1996-10-10	DUSUN PAHLAWAN	137	2024-04-04 08:42:54	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	0	\N
OP074648-040424-0060	RJJP040424-0481	07-46-48	MUHAMMAD RIZAL, AN	KEPANITERAAN FKG	VI-11	M	2016-01-30	JL. CEMPAKA PUTIH TIMUR	58	2024-04-04 12:41:23	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP073957-050424-0077	RJJP050424-0235	07-39-57	PRADNYA FAIZATUZIHAN AZKIA, NN	KEPANITERAAN FKG	DU-35	F	2002-04-09	TEMBALANG PESONA ASRI L-17	137	2024-04-05 09:25:20	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	0	\N
OP022036-190424-0181	RJJP190424-0325	02-20-36	PASIEN TESTING BPJS	KEPANITERAAN FKG	VN-1	M	2021-01-31	JL. BPSJ	46	2024-04-19 11:00:21	Poli Gigi Spesialis Orthodonty	2478	drg. Vika Novia Zamri, Sp.Ort	PERUSAHAAN	0	\N
OP003702-190424-0034	RJJP190424-0294	00-37-02	Test Daewong 2,Tn	KEPANITERAAN FKG	VI-1	M	1991-01-01	jsjd	58	2024-04-19 10:17:36	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP000127-070224-0029	RJJP190424-0289	00-01-27	TEST ENDOSKOPI	KEPANITERAAN FKG	SQ-21	M	1990-06-26	LLRRRRTTT	137	2024-04-19 10:07:05	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	0	\N
OP074661-220424-0171	RJJP220424-0206	07-46-61	SHINTA DEWI, NY	KEPANITERAAN FKG	GY-37	F	2000-03-28	JL. DESTOROTO NO. 11	59	2024-04-22 08:38:31	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP076902-160424-0030	RJJP160424-0306	07-69-02	PUTRI AYU NURHADIZAH, NN	KEPANITERAAN FKG	VN-2	F	2002-10-04	BALIMATRAMAN NO. 6	46	2024-04-16 10:27:53	Poli Gigi Spesialis Orthodonty	2478	drg. Vika Novia Zamri, Sp.Ort	PERUSAHAAN	4	\N
OP052564-160424-0027	RJJP160424-0303	05-25-64	RAYYEN ALFRIAN JUNEANDRO,TN	KEPANITERAAN FKG	VN-1	M	2002-06-26	JL TITIHAN 6 BLOK HF 13 NO 14	46	2024-04-16 10:25:56	Poli Gigi Spesialis Orthodonty	2478	drg. Vika Novia Zamri, Sp.Ort	PERUSAHAAN	4	\N
OP074083-230424-0064	RJJP230424-0411	07-40-83	JIHAN AR ROHIM, NY	KEPANITERAAN FKG	GY-36	F	2002-06-30	JL. BINTARA RAYA AA 99/4	59	2024-04-23 11:18:37	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP073195-230424-0062	RJJP230424-0409	07-31-95	FAIKA ZAHRA CHAIRUNISA, NN	KEPANITERAAN FKG	GY-35	F	2002-07-09	JL SPG VII	59	2024-04-23 11:17:35	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP076047-230424-0061	RJJP230424-0408	07-60-47	QANITA REGINA MAHARANI, NN	KEPANITERAAN FKG	GY-34	F	2002-09-01	KOMPLEK KIMIA FARMA II BLOK AG.9/8	59	2024-04-23 11:16:41	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP073107-230424-0059	RJJP230424-0406	07-31-07	FARAH ALIFAH RAHAYU, NN	KEPANITERAAN FKG	GY-33	F	2002-08-02	JL KRIDA MANDALA II	59	2024-04-23 11:16:30	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP073103-230424-0058	RJJP230424-0405	07-31-03	KARINA IVANA NARISWARI, NN	KEPANITERAAN FKG	GY-32	F	2002-01-25	KEBON PALA I	59	2024-04-23 11:15:12	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP076046-230424-0055	RJJP230424-0402	07-60-46	LARAS FAJRI NANDA WIDIISWA, NN	KEPANITERAAN FKG	GY-30	F	2002-03-07	JL Y NO 21 A	59	2024-04-23 11:13:26	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP073703-230424-0057	RJJP230424-0404	07-37-03	SEKAR DECITA ANANDA I, NN	KEPANITERAAN FKG	GY-31	F	2002-06-08	JL. KEMUNING 4B	59	2024-04-23 11:12:41	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP075860-280324-0555	RJJP280324-0556	07-58-60	IVAN HASAN, TN	KEPANITERAAN FKG	GY-44	M	2000-02-24	JL H SUAIB	59	2024-03-28 14:43:21	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP075854-280324-0533	RJJP280324-0534	07-58-54	ADILA HIKMAYANTI, NN	KEPANITERAAN FKG	GY-43	F	2002-06-23	KP PUTAT	59	2024-03-28 14:18:01	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP075853-280324-0530	RJJP280324-0531	07-58-53	AMALIA RAFA WULANDARI, NN	KEPANITERAAN FKG	GY-42	F	2002-06-08	JL. IPTN KP. PEDURENAN	59	2024-03-28 14:13:36	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP057971-280324-0528	RJJP280324-0529	05-79-71	JESSICA PUTRI SOUISA, NN	KEPANITERAAN FKG	GY-41	F	2002-03-08	JLN RADEN FATAH NO 03 RT : 016/003	59	2024-03-28 14:12:16	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP034510-280324-0526	RJJP280324-0527	03-45-10	KHAIRUNNISA NABIILAH PUTRI, AN	KEPANITERAAN FKG	GY-40	F	2002-01-23	JLN CEMPAKA PUTIH TENGAH 1 NO 21 B	59	2024-03-28 14:10:13	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP075852-280324-0231	RJJP280324-0519	07-58-52	MUTIA PERMATA PUTRI, NN	KEPANITERAAN FKG	GY-39	F	2002-08-28	KP BULU	59	2024-03-28 14:02:21	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP074096-260324-0068	RJJP260324-0450	07-40-96	DODY PRIBADI, TN	KEPANITERAAN FKG	HE-47	M	1981-03-10	JL CIBUBUR 7 GG MANGGA DUA	137	2024-03-26 13:04:09	Poli Gigi Spesialis Konservasi/Endodonsi	3888	drg. Hesti Witasari Jos Erry, Sp.KG	PERUSAHAAN	4	\N
OP075642-260324-0396	RJJP260324-0386	07-56-42	ALFAT FADILAH NUR, TN	KEPANITERAAN FKG	SQ-5	M	1996-10-10	DUSUN PAHLAWAN	137	2024-03-26 10:41:40	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP075646-260324-0390	RJJP260324-0356	07-56-46	SHABRINA GHISANI MARZUKI, NN	KEPANITERAAN FKG	VN-6	F	2002-06-21	JL. NEFTUNUS PRAYA BLOK  I 1 NO. 20	46	2024-03-26 10:09:07	Poli Gigi Spesialis Orthodonty	2478	drg. Vika Novia Zamri, Sp.Ort	PERUSAHAAN	4	\N
OP075572-260324-0384	RJJP260324-0350	07-55-72	ATIKA RAHMA MINABARI, NY	KEPANITERAAN FKG	VN-5	F	2000-12-18	JL CENDRAWASIH NO. 99	46	2024-03-26 10:07:45	Poli Gigi Spesialis Orthodonty	2478	drg. Vika Novia Zamri, Sp.Ort	PERUSAHAAN	4	\N
OP075535-260324-0385	RJJP260324-0347	07-55-35	IVO RESKY PRIMIGO, NN	KEPANITERAAN FKG	VN-4	F	2001-07-21	JL. HALIMAH 	46	2024-03-26 10:04:33	Poli Gigi Spesialis Orthodonty	2478	drg. Vika Novia Zamri, Sp.Ort	PERUSAHAAN	4	\N
OP075644-260324-0395	RJJP260324-0336	07-56-44	ANDI ADJANI SALWA PUTRI, NN	KEPANITERAAN FKG	VN-3	F	2003-08-11	PERUM SEPINGGAN PRATAMA BLOK E1 NO. 5	46	2024-03-26 09:51:18	Poli Gigi Spesialis Orthodonty	2478	drg. Vika Novia Zamri, Sp.Ort	PERUSAHAAN	4	\N
OP075572-260324-0384	RJJP260324-0317	07-55-72	ATIKA RAHMA MINABARI, NY	KEPANITERAAN FKG	SQ-3	F	2000-12-18	JL CENDRAWASIH NO. 99	137	2024-03-26 09:39:35	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP075631-260324-0379	RJJP260324-0312	07-56-31	SIERRA MALIKA PUTRI, AN	KEPANITERAAN FKG	VI-12	F	2017-01-12	JL JENGKI CIPINANG ASEM NO. 3	58	2024-03-26 09:37:42	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	4	\N
OP074808-260324-0434	RJJP260324-0243	07-48-08	ANGGI PRASETYO, TN	KEPANITERAAN FKG	SQ-2	M	1993-07-10	JL. BATU	137	2024-03-26 08:58:22	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP074648-260324-0364	RJJP260324-0152	07-46-48	MUHAMMAD RIZAL, AN	KEPANITERAAN FKG	VI-11	M	2016-01-30	JL. CEMPAKA PUTIH TIMUR	58	2024-03-26 08:05:32	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	4	\N
OP071328-250324-0223	RJJP250324-0441	07-13-28	MARLINA BINTI MARTO ,NY	KEPANITERAAN FKG	DU-42	F	1979-03-14	JL SALEMBA TENGAH	137	2024-03-25 11:32:08	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP071328-250324-0076	RJJP250324-0294	07-13-28	MARLINA BINTI MARTO ,NY	KEPANITERAAN FKG	DU-40	F	1979-03-14	JL SALEMBA TENGAH	137	2024-03-25 09:40:21	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP074808-250324-0073	RJJP250324-0291	07-48-08	ANGGI PRASETYO, TN	KEPANITERAAN FKG	DU-39	M	1993-07-10	JL. BATU	137	2024-03-25 09:38:01	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP074181-250324-0061	RJJP250324-0215	07-41-81	AGNES SUKARSIH, NY	KEPANITERAAN FKG	DU-38	F	1960-07-27	JL. ANGIN SEJUK IV NO. 31	137	2024-03-25 08:52:12	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP073108-220324-0004	RJJP220324-0357	07-31-08	SAHRI MUHAMAD RIZKY, TN 	KEPANITERAAN FKG	SQ-21	M	2000-07-18	JL AK GANI 	137	2024-03-22 10:57:20	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP066705-220324-0003	RJJP220324-0356	06-67-05	ONG KU AN, TN	KEPANITERAAN FKG	DU-43	M	1971-09-21	JL. GG TOYIB NO. 1A	137	2024-03-22 10:55:21	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP074808-220324-0199	RJJP220324-0327	07-48-08	ANGGI PRASETYO, TN	KEPANITERAAN FKG	SQ-20	M	1993-07-10	JL. BATU	137	2024-03-22 10:15:03	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP075268-210324-0120	RJJP220324-0226	07-52-68	AGNA TRI KALIDAN, AN	KEPANITERAAN FKG	SQ-19	M	2008-04-13	JL. RH. UMAR	137	2024-03-22 09:07:44	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP074181-220324-0220	RJJP220324-0224	07-41-81	AGNES SUKARSIH, NY	KEPANITERAAN FKG	DU-41	F	1960-07-27	JL. ANGIN SEJUK IV NO. 31	137	2024-03-22 09:05:32	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP074181-220324-0220	RJJP220324-0221	07-41-81	AGNES SUKARSIH, NY	KEPANITERAAN FKG	SQ-18	F	1960-07-27	JL. ANGIN SEJUK IV NO. 31	137	2024-03-22 09:04:21	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP074808-220324-0199	RJJP220324-0200	07-48-08	ANGGI PRASETYO, TN	KEPANITERAAN FKG	DU-40	M	1993-07-10	JL. BATU	137	2024-03-22 08:50:47	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP074096-200324-0061	RJJP210324-0493	07-40-96	DODY PRIBADI, TN	KEPANITERAAN FKG	HE-39	M	1981-03-10	JL CIBUBUR 7 GG MANGGA DUA	137	2024-03-21 13:41:16	Poli Gigi Spesialis Konservasi/Endodonsi	3888	drg. Hesti Witasari Jos Erry, Sp.KG	PERUSAHAAN	4	\N
OP074738-210324-0129	RJJP210324-0466	07-47-38	BAGAS DWI SAPUTRA, TN	KEPANITERAAN FKG	GY-38	M	2002-07-02	BALIMATRAMAN NO. 5	59	2024-03-21 13:07:08	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP074081-210324-0153	RJJP210324-0437	07-40-81	SUMIRAH DEWI, NN	KEPANITERAAN FKG	GY-37	F	2003-02-04	JL. BUNGUR BESAR XIV NO. 83	59	2024-03-21 12:10:50	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP071781-210324-0127	RJJP210324-0369	07-17-81	KAFKA RAFAN ELFATIH, TN	KEPANITERAAN FKG	DU-41	M	2008-08-10	JL KRAMAT KWITANG 2 UJUNG NO 1	137	2024-03-21 10:25:55	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP075261-210324-0123	RJJP210324-0365	07-52-61	REZZA ZAKI MAULANA, AN	KEPANITERAAN FKG	VI-10	M	2015-03-25	KP BEND MELAYU	58	2024-03-21 10:21:58	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	4	\N
OP075268-210324-0120	RJJP210324-0350	07-52-68	AGNA TRI KALIDAN, AN	KEPANITERAAN FKG	SQ-21	M	2008-04-13	JL. RH. UMAR	137	2024-03-21 10:06:17	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP074081-210324-0104	RJJP210324-0334	07-40-81	SUMIRAH DEWI, NN	KEPANITERAAN FKG	GY-35	F	2003-02-04	JL. BUNGUR BESAR XIV NO. 83	59	2024-03-21 09:57:36	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP074661-210324-0132	RJJP210324-0290	07-46-61	SHINTA DEWI, NY	KEPANITERAAN FKG	GY-33	F	2000-03-28	JL. DESTOROTO NO. 11	59	2024-03-21 09:36:40	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP072314-210324-0131	RJJP210324-0186	07-23-14	RITA AGUSTIN. NY	KEPANITERAAN FKG	DU-37	F	1990-08-12	PERUM BUMI PERMATA ESTATE	137	2024-03-21 08:22:17	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP074560-210324-0118	RJJP210324-0170	07-45-60	AISYAH NURAILAH, AN	KEPANITERAAN FKG	VI-9	F	2018-06-22	JL. 25 DUREN SAWIT	58	2024-03-21 08:14:33	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	4	\N
OP073621-190324-0046	RJJP190324-0425	07-36-21	ANA ANGELIA ADITASARI, NN	KEPANITERAAN FKG	GY-38	F	1995-06-09	KP BULU	59	2024-03-19 11:27:50	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073617-190324-0037	RJJP190324-0377	07-36-17	MUNANIK, NY	KEPANITERAAN FKG	SQ-1	F	1970-03-06	KP BULU RT. 4 RW. 10	137	2024-03-19 10:04:16	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP073765-190324-0019	RJJP190324-0291	07-37-65	NUR AUDI LARASATI, NN	KEPANITERAAN FKG	GY-37	F	2002-07-30	JL. ARGA MALABAT BLOK D8 NO.14	59	2024-03-19 09:22:33	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP074172-190324-0090	RJJP190324-0266	07-41-72	WULAN RAMADANI, NN	KEPANITERAAN FKG	GY-36	F	2002-11-11	JL. PERTANINAN	59	2024-03-19 09:07:36	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073953-190324-0089	RJJP190324-0265	07-39-53	RAFIQA NURUL ISNAIN, NN	KEPANITERAAN FKG	GY-35	F	2004-04-28	JL. KAYU MAS	59	2024-03-19 09:06:12	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP074648-190324-0051	RJJP190324-0055	07-46-48	MUHAMMAD RIZAL, AN	KEPANITERAAN FKG	VI-11	M	2016-01-30	JL. CEMPAKA PUTIH TIMUR	58	2024-03-19 07:35:11	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	4	\N
OP074169-180324-0193	RJJP180324-0406	07-41-69	MUHAMMAD FARIZ AKBAR, TN	KEPANITERAAN FKG	GY-35	M	2001-09-22	JL. DUKU BLOK D-8 NO.14	59	2024-03-18 10:29:22	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073957-180324-0087	RJJP180324-0384	07-39-57	PRADNYA FAIZATUZIHAN AZKIA, NN	KEPANITERAAN FKG	GY-34	F	2002-04-09	TEMBALANG PESONA ASRI L-17	59	2024-03-18 10:13:35	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP074817-180324-0047	RJJP180324-0321	07-48-17	MUHAMMAD TAUFIK, TN	KEPANITERAAN FKG	GY-32	M	1997-06-23	JL. DANAU MANINJAU V	59	2024-03-18 09:32:33	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP074808-150324-0254	RJJP180324-0240	07-48-08	ANGGI PRASETYO, TN	KEPANITERAAN FKG	DU-44	M	1993-07-10	JL. BATU	137	2024-03-18 08:44:13	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP071105-150324-0240	RJJP150324-0425	07-11-05	MAIMUNAH M TAUHID,NY	KEPANITERAAN FKG	BR-16	F	1968-10-14	JL.CEMAPAKA BARU IV	60	2024-03-15 12:55:31	Poli Gigi Spesialis Prostodonti	3859	drg. Bimo Rintoko, Sp.Pros	PERUSAHAAN	4	\N
OP074813-150324-0015	RJJP150324-0292	07-48-13	FAIKA ZAHRA CHAIRUNISA	KEPANITERAAN FKG	SQ-25	F	2002-07-09	JL. SPG VII	137	2024-03-15 09:27:16	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP066649-150324-0314	RJJP150324-0285	06-66-49	SITI AMINAH, NY	KEPANITERAAN FKG	BR-15	F	1980-01-19	JALAN SUKAMULYA 4 NO 120 RT.009/006	60	2024-03-15 09:24:30	Poli Gigi Spesialis Prostodonti	3859	drg. Bimo Rintoko, Sp.Pros	PERUSAHAAN	4	\N
OP071611-150324-0050	RJJP150324-0081	07-16-11	KEYLA GHIRIA PUTRI, NN	KEPANITERAAN FKG	DU-40	F	2008-05-11	JL. TANAH TINGGI SAWAH NO 8 10\\12	137	2024-03-15 07:37:37	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP074738-140324-0010	RJJP140324-0398	07-47-38	BAGAS DWI SAPUTRA, TN	KEPANITERAAN FKG	GY-36	M	2002-07-02	BALIMATRAMAN NO. 5	59	2024-03-14 10:55:11	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP074661-130324-0325	RJJP130324-0586	07-46-61	SHINTA DEWI, NY	KEPANITERAAN FKG	GY-29	F	2000-03-28	JL. DESTOROTO NO. 11	59	2024-03-13 14:31:57	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP071328-130324-0403	RJJP130324-0566	07-13-28	MARLINA BINTI MARTO ,NY	KEPANITERAAN FKG	DU-46	F	1979-03-14	JL SALEMBA TENGAH	137	2024-03-13 14:00:28	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP071328-130324-0377	RJJP130324-0540	07-13-28	MARLINA BINTI MARTO ,NY	KEPANITERAAN FKG	DU-44	F	1979-03-14	JL SALEMBA TENGAH	137	2024-03-13 13:54:04	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP071611-130324-0315	RJJP130324-0510	07-16-11	KEYLA GHIRIA PUTRI, NN	KEPANITERAAN FKG	DU-43	F	2008-05-11	JL. TANAH TINGGI SAWAH NO 8 10\\12	137	2024-03-13 13:37:47	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP074083-130324-0211	RJJP130324-0430	07-40-83	JIHAN AR ROHIM, NY	KEPANITERAAN FKG	GY-26	F	2002-06-30	JL. BINTARA RAYA AA 99/4	59	2024-03-13 12:23:01	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073193-130324-0214	RJJP130324-0366	07-31-93	DINDA KANIA LARASATI, NN	KEPANITERAAN FKG	SQ-32	F	2002-07-27	BLOK R GG II / 63	137	2024-03-13 11:16:18	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP073380-130324-0329	RJJP130324-0333	07-33-80	AYASMINE VENEZIA ACHMAD, NN	KEPANITERAAN FKG	SQ-31	F	2007-01-10	JL SWASEMBADA BARAT VIII NO 29	137	2024-03-13 10:45:37	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP073213-130324-0362	RJJP130324-0305	07-32-13	JUSLY EDWIN SOUISA, ST, TN 	KEPANITERAAN FKG	BR-15	M	1978-06-26	KP LIO RT 008/003	60	2024-03-13 10:14:42	Poli Gigi Spesialis Prostodonti	3859	drg. Bimo Rintoko, Sp.Pros	PERUSAHAAN	4	\N
OP064493-130324-0340	RJJP130324-0283	06-44-93	MUJLIPAH,NY	KEPANITERAAN FKG	BR-14	F	1966-04-01	JL.JOHAR BARU UTARA I	60	2024-03-13 09:58:22	Poli Gigi Spesialis Prostodonti	3859	drg. Bimo Rintoko, Sp.Pros	PERUSAHAAN	4	\N
OP073795-130324-0317	RJJP130324-0259	07-37-95	MUHARRAM RACHMATIAR, TN	KEPANITERAAN FKG	GY-25	M	2003-03-07	JL. ELANG INDOPURA BLOK B 1 NO.16	59	2024-03-13 09:40:45	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP074575-130324-0274	RJJP130324-0216	07-45-75	CANTIKA PUTRI ALMIA, AN	KEPANITERAAN FKG	VI-12	F	2015-07-07	CEMPAKA PUTIH BARAT	58	2024-03-13 09:10:09	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	4	\N
OP074570-130324-0186	RJJP130324-0184	07-45-70	NABILA PUTRI ANISA, AN	KEPANITERAAN FKG	VI-11	F	2015-12-13	JL CEMPAKA PUTIH BARAT XI NO 4	58	2024-03-13 08:51:18	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	4	\N
OP074081-120324-0218	RJJP120324-0470	07-40-81	SUMIRAH DEWI, NN	KEPANITERAAN FKG	GY-34	F	2003-02-04	JL. BUNGUR BESAR XIV NO. 83	59	2024-03-12 14:00:09	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP074581-120324-0218	RJJP120324-0404	07-45-81	DEWI AFRIYANTI NURHASANAH, NN	KEPANITERAAN FKG	GY-33	F	2001-04-29	JL BUMI AYU	59	2024-03-12 11:46:17	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073962-120324-0277	RJJP120324-0198	07-39-62	NUR FADILLAH, TN	KEPANITERAAN FKG	GY-30	M	2004-03-11	GG. BAHASWAN NO. 80	59	2024-03-12 08:43:55	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073107-080324-0131	RJJP080324-0422	07-31-07	FARAH ALIFAH RAHAYU, NN	KEPANITERAAN FKG	SQ-36	F	2002-08-02	JL KRIDA MANDALA II	137	2024-03-08 10:45:01	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP073505-080324-0085	RJJP080324-0356	07-35-05	AULIA MAULIDA FITRIANI. NN	KEPANITERAAN FKG	SQ-35	F	2005-03-11	JL NURUL HUDA I NO 2\r\n002/015	137	2024-03-08 09:50:21	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP073380-080324-0071	RJJP080324-0342	07-33-80	AYASMINE VENEZIA ACHMAD, NN	KEPANITERAAN FKG	SQ-34	F	2007-01-10	JL SWASEMBADA BARAT VIII NO 29	137	2024-03-08 09:39:22	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP073193-080324-0068	RJJP080324-0339	07-31-93	DINDA KANIA LARASATI, NN	KEPANITERAAN FKG	SQ-33	F	2002-07-27	BLOK R GG II / 63	137	2024-03-08 09:37:15	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP074315-070324-0227	RJJP070324-0538	07-43-15	IRFAN FAUZI, TN	KEPANITERAAN FKG	HE-36	M	1996-02-22	DUSUN ANGGREK GALA HERAN	137	2024-03-07 13:26:02	Poli Gigi Spesialis Konservasi/Endodonsi	3888	drg. Hesti Witasari Jos Erry, Sp.KG	PERUSAHAAN	4	\N
OP033171-070324-0265	RJJP070324-0481	03-31-71	SALMA KALZHUM, NN	KEPANITERAAN FKG	GY-30	F	2002-06-23	KP. KARANG MULYA NO. 10 RT 004/002	59	2024-03-07 11:27:50	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073703-070324-0256	RJJP070324-0472	07-37-03	SEKAR DECITA ANANDA I, NN	KEPANITERAAN FKG	GY-29	F	2002-06-08	JL. KEMUNING 4B	59	2024-03-07 11:19:32	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073105-070324-0116	RJJP070324-0325	07-31-05	RADIUS DELANO TRI SATYA, TN 	KEPANITERAAN FKG	SQ-30	M	1999-04-05	PONDOK KOPI BLOK U.I NO 10 RT 007/006	137	2024-03-07 09:21:14	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP072314-070324-0039	RJJP070324-0227	07-23-14	RITA AGUSTIN. NY	KEPANITERAAN FKG	DU-32	F	1990-08-12	PERUM BUMI PERMATA ESTATE	137	2024-03-07 08:39:05	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP071611-060324-0018	RJJP060324-0594	07-16-11	KEYLA GHIRIA PUTRI, NN	KEPANITERAAN FKG	DU-45	F	2008-05-11	JL. TANAH TINGGI SAWAH NO 8 10\\12	137	2024-03-06 15:33:01	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP041575-060324-0311	RJJP060324-0565	04-15-75	NASYWA DESTIANI,NN	KEPANITERAAN FKG	GY-33	F	2002-12-16	KOMP DEPAG BLOK G NO 8	59	2024-03-06 14:54:59	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP071756-060324-0050	RJJP060324-0500	07-17-56	JANUAR BASTIAN MAKATUTU	KEPANITERAAN FKG	DU-44	M	1991-01-12	JL PERCETAKAN NEGARA X	137	2024-03-06 13:37:08	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP071781-060324-0313	RJJP060324-0455	07-17-81	KAFKA RAFAN ELFATIH, TN	KEPANITERAAN FKG	DU-40	M	2008-08-10	JL KRAMAT KWITANG 2 UJUNG NO 1	137	2024-03-06 12:41:21	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP074181-060324-0042	RJJP060324-0400	07-41-81	AGNES SUKARSIH, NY	KEPANITERAAN FKG	BR-20	F	1960-07-27	JL. ANGIN SEJUK IV NO. 31	60	2024-03-06 11:03:20	Poli Gigi Spesialis Prostodonti	3859	drg. Bimo Rintoko, Sp.Pros	PERUSAHAAN	4	\N
OP073193-060324-0013	RJJP060324-0364	07-31-93	DINDA KANIA LARASATI, NN	KEPANITERAAN FKG	DU-38	F	2002-07-27	BLOK R GG II / 63	137	2024-03-06 10:37:51	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP074172-060324-0037	RJJP060324-0344	07-41-72	WULAN RAMADANI, NN	KEPANITERAAN FKG	GY-32	F	2002-11-11	JL. PERTANINAN	59	2024-03-06 10:21:47	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP074169-060324-0141	RJJP060324-0299	07-41-69	MUHAMMAD FARIZ AKBAR, TN	KEPANITERAAN FKG	GY-31	M	2001-09-22	JL. DUKU BLOK D-8 NO.14	59	2024-03-06 09:44:18	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073380-050324-0203	RJJP050324-0481	07-33-80	AYASMINE VENEZIA ACHMAD, NN	KEPANITERAAN FKG	DU-43	F	2007-01-10	JL SWASEMBADA BARAT VIII NO 29	137	2024-03-05 12:13:34	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP074096-050324-0388	RJJP050324-0460	07-40-96	DODY PRIBADI, TN	KEPANITERAAN FKG	HE-57	M	1981-03-10	JL CIBUBUR 7 GG MANGGA DUA	137	2024-03-05 11:21:16	Poli Gigi Spesialis Konservasi/Endodonsi	3888	drg. Hesti Witasari Jos Erry, Sp.KG	PERUSAHAAN	4	\N
OP074083-050324-0263	RJJP050324-0425	07-40-83	JIHAN AR ROHIM, NY	KEPANITERAAN FKG	GY-32	F	2002-06-30	JL. BINTARA RAYA AA 99/4	59	2024-03-05 10:32:34	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP074081-050324-0259	RJJP050324-0421	07-40-81	SUMIRAH DEWI, NN	KEPANITERAAN FKG	GY-31	F	2003-02-04	JL. BUNGUR BESAR XIV NO. 83	59	2024-03-05 10:26:34	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073107-050324-0334	RJJP050324-0288	07-31-07	FARAH ALIFAH RAHAYU, NN	KEPANITERAAN FKG	SQ-3	F	2002-08-02	JL KRIDA MANDALA II	137	2024-03-05 09:03:52	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP073105-050324-0048	RJJP050324-0131	07-31-05	RADIUS DELANO TRI SATYA, TN 	KEPANITERAAN FKG	DU-41	M	1999-04-05	PONDOK KOPI BLOK U.I NO 10 RT 007/006	137	2024-03-05 08:08:23	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP073505-050324-0207	RJJP050324-0102	07-35-05	AULIA MAULIDA FITRIANI. NN	KEPANITERAAN FKG	SQ-2	F	2005-03-11	JL NURUL HUDA I NO 2\r\n002/015	137	2024-03-05 07:56:36	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP073380-050324-0203	RJJP050324-0098	07-33-80	AYASMINE VENEZIA ACHMAD, NN	KEPANITERAAN FKG	SQ-1	F	2007-01-10	JL SWASEMBADA BARAT VIII NO 29	137	2024-03-05 07:55:06	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP073962-040324-0039	RJJP040324-0367	07-39-62	NUR FADILLAH, TN	KEPANITERAAN FKG	GY-44	M	2004-03-11	GG. BAHASWAN NO. 80	59	2024-03-04 10:01:34	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073957-040324-0278	RJJP040324-0348	07-39-57	PRADNYA FAIZATUZIHAN AZKIA, NN	KEPANITERAAN FKG	GY-43	F	2002-04-09	TEMBALANG PESONA ASRI L-17	59	2024-03-04 09:49:25	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073953-040324-0261	RJJP040324-0325	07-39-53	RAFIQA NURUL ISNAIN, NN	KEPANITERAAN FKG	GY-42	F	2004-04-28	JL. KAYU MAS	59	2024-03-04 09:35:07	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP066649-040324-0205	RJJP040324-0256	06-66-49	SITI AMINAH, NY	KEPANITERAAN FKG	BR-14	F	1980-01-19	JALAN SUKAMULYA 4 NO 120 RT.009/006	60	2024-03-04 08:51:05	Poli Gigi Spesialis Prostodonti	3859	drg. Bimo Rintoko, Sp.Pros	PERUSAHAAN	4	\N
OP073380-040324-0193	RJJP040324-0244	07-33-80	AYASMINE VENEZIA ACHMAD, NN	KEPANITERAAN FKG	DU-41	F	2007-01-10	JL SWASEMBADA BARAT VIII NO 29	137	2024-03-04 08:46:40	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP073935-040324-0185	RJJP040324-0183	07-39-35	VIOLA AL AQSA, NN	KEPANITERAAN FKG	DU-40	F	2001-04-11	KP LOCOMOTIF 	137	2024-03-04 08:17:06	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP073795-010324-0409	RJJP010324-0320	07-37-95	MUHARRAM RACHMATIAR, TN	KEPANITERAAN FKG	GY-6	M	2003-03-07	JL. ELANG INDOPURA BLOK B 1 NO.16	59	2024-03-01 10:37:07	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073108-010324-0418	RJJP010324-0225	07-31-08	SAHRI MUHAMAD RIZKY, TN 	KEPANITERAAN FKG	SQ-26	M	2000-07-18	JL AK GANI 	137	2024-03-01 09:07:00	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP073601-010324-0407	RJJP010324-0214	07-36-01	AMALIA SALSABILA, NN	KEPANITERAAN FKG	SQ-25	F	2000-04-21	JL. HAJI HASBI 2 NO.17	137	2024-03-01 09:03:14	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP067212-010324-0365	RJJP010324-0136	06-72-12	TANIA RESTIANA, NN	KEPANITERAAN FKG	DU-37	F	2000-05-14	JL MANGGAN BESAR XIII RT.005/003	137	2024-03-01 08:21:13	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP073765-010324-0363	RJJP010324-0133	07-37-65	NUR AUDI LARASATI, NN	KEPANITERAAN FKG	GY-4	F	2002-07-30	JL. ARGA MALABAT BLOK D8 NO.14	59	2024-03-01 08:17:25	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP033171-290224-0229	RJJP290224-0335	03-31-71	SALMA KALZHUM, NN	KEPANITERAAN FKG	GY-34	F	2002-06-23	KP. KARANG MULYA NO. 10 RT 004/002	59	2024-02-29 10:51:39	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073703-290224-0194	RJJP290224-0297	07-37-03	SEKAR DECITA ANANDA I, NN	KEPANITERAAN FKG	GY-33	F	2002-06-08	JL. KEMUNING 4B	59	2024-02-29 10:28:48	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP041575-280224-0174	RJJP280224-0349	04-15-75	NASYWA DESTIANI,NN	KEPANITERAAN FKG	GY-26	F	2002-12-16	KOMP DEPAG BLOK G NO 8	59	2024-02-28 12:04:49	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
-	RKG260524-2448	-	Periapikal 4	KEPANITERAAN FKG	-	F	2024-05-26	-	10	2024-05-26 00:38:40	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
OP073621-280224-0061	RJJP280224-0302	07-36-21	ANA ANGELIA ADITASARI, NN	KEPANITERAAN FKG	GY-25	F	1995-06-09	KP BULU	59	2024-02-28 11:00:19	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073617-280224-0044	RJJP280224-0282	07-36-17	MUNANIK, NY	KEPANITERAAN FKG	SQ-23	F	1970-03-06	KP BULU RT. 4 RW. 10	137	2024-02-28 10:45:32	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP067212-280224-0282	RJJP280224-0209	06-72-12	TANIA RESTIANA, NN	KEPANITERAAN FKG	DU-37	F	2000-05-14	JL MANGGAN BESAR XIII RT.005/003	137	2024-02-28 09:40:37	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP073601-280224-0272	RJJP280224-0199	07-36-01	AMALIA SALSABILA, NN	KEPANITERAAN FKG	SQ-21	F	2000-04-21	JL. HAJI HASBI 2 NO.17	137	2024-02-28 09:30:06	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP071756-270224-0086	RJJP270224-0349	07-17-56	JANUAR BASTIAN MAKATUTU	KEPANITERAAN FKG	DU-44	M	1991-01-12	JL PERCETAKAN NEGARA X	137	2024-02-27 09:43:20	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP073519-270224-0077	RJJP270224-0337	07-35-19	WARYONO HERMAN, TN	KEPANITERAAN FKG	DU-43	M	1987-08-24	DUSUN 02	137	2024-02-27 09:36:02	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP073505-270224-0059	RJJP270224-0194	07-35-05	AULIA MAULIDA FITRIANI. NN	KEPANITERAAN FKG	DU-41	F	2005-03-11	JL NURUL HUDA I NO 2\r\n002/015	137	2024-02-27 08:22:38	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP073380-260224-0118	RJJP260224-0148	07-33-80	AYASMINE VENEZIA ACHMAD, NN	KEPANITERAAN FKG	DU-46	F	2007-01-10	JL SWASEMBADA BARAT VIII NO 29	137	2024-02-26 08:05:23	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP073244-230224-0351	RJJP230224-0457	07-32-44	YANUAR AL HADID, TN 	KEPANITERAAN FKG	SQ-23	M	2003-01-03	JL GALUR SELATAN RT 010/003	137	2024-02-23 13:59:31	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP073213-230224-0118	RJJP230224-0348	07-32-13	JUSLY EDWIN SOUISA, ST, TN 	KEPANITERAAN FKG	BR-13	M	1978-06-26	KP LIO RT 008/003	60	2024-02-23 10:39:48	Poli Gigi Spesialis Prostodonti	3859	drg. Bimo Rintoko, Sp.Pros	PERUSAHAAN	4	\N
OP066705-230224-0116	RJJP230224-0346	06-67-05	ONG KU AN, TN	KEPANITERAAN FKG	DU-50	M	1971-09-21	JL. GG TOYIB NO. 1A	137	2024-02-23 10:38:25	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP073193-230224-0094	RJJP230224-0324	07-31-93	DINDA KANIA LARASATI, NN	KEPANITERAAN FKG	SQ-22	F	2002-07-27	BLOK R GG II / 63	137	2024-02-23 10:01:11	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP073195-230224-0110	RJJP230224-0305	07-31-95	FAIKA ZAHRA CHAIRUNISA, NN	KEPANITERAAN FKG	DU-49	F	2002-07-09	JL SPG VII	137	2024-02-23 09:42:20	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP073193-230224-0094	RJJP230224-0298	07-31-93	DINDA KANIA LARASATI, NN	KEPANITERAAN FKG	DU-48	F	2002-07-27	BLOK R GG II / 63	137	2024-02-23 09:35:00	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP073108-220224-0167	RJJP220224-0387	07-31-08	SAHRI MUHAMAD RIZKY, TN 	KEPANITERAAN FKG	DU-42	M	2000-07-18	JL AK GANI 	137	2024-02-22 10:16:14	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP073107-220224-0163	RJJP220224-0383	07-31-07	FARAH ALIFAH RAHAYU, NN	KEPANITERAAN FKG	DU-41	F	2002-08-02	JL KRIDA MANDALA II	137	2024-02-22 10:12:40	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP073105-220224-0161	RJJP220224-0381	07-31-05	RADIUS DELANO TRI SATYA, TN 	KEPANITERAAN FKG	DU-40	M	1999-04-05	PONDOK KOPI BLOK U.I NO 10 RT 007/006	137	2024-02-22 10:07:16	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP073103-220224-0156	RJJP220224-0376	07-31-03	KARINA IVANA NARISWARI, NN	KEPANITERAAN FKG	DU-39	F	2002-01-25	KEBON PALA I	137	2024-02-22 09:30:23	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP078974-070524-0119	RJJP070524-0430	07-89-74	NIBRAS MUHAMMAD RASHIF, TN	KEPANITERAAN FKG	SQ-4	M	2000-02-12	JL. KELURAHAN LAMA NO. 35	137	2024-05-07 10:11:47	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	0	\N
OP074083-060524-0163	RJJP070524-0415	07-40-83	JIHAN AR ROHIM, NY	KEPANITERAAN FKG	DU-49	F	2002-06-30	JL. BINTARA RAYA AA 99/4	137	2024-05-07 10:07:02	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	0	\N
OP075642-070524-0172	RJJP070524-0400	07-56-42	ALFAT FADILAH NUR, TN	KEPANITERAAN FKG	SQ-3	M	1996-10-10	DUSUN PAHLAWAN	137	2024-05-07 09:58:12	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	0	\N
OP078954-070524-0164	RJJP070524-0299	07-89-54	NAFISAH AMALIA, NY	KEPANITERAAN FKG	GY-34	F	2001-09-29	JL. KALIBARU BARAT VII	59	2024-05-07 08:57:51	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP079163-080524-0145	RJJP080524-0580	07-91-63	ANINDITA VALENT SUGIANTO, AN	KEPANITERAAN FKG	DU-50	F	2012-02-22	BEBEDAHAN	137	2024-05-08 14:01:33	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	0	\N
OP076902-080524-0118	RJJP080524-0553	07-69-02	PUTRI AYU NURHADIZAH, NN	KEPANITERAAN FKG	SQ-38	F	2002-10-04	BALIMATRAMAN NO. 6	137	2024-05-08 13:30:07	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	0	\N
OP048992-080524-0171	RJJP080524-0590	04-89-92	SITI KHODIJAH, NY	KEPANITERAAN FKG	DU-52	F	1982-07-23	JALAN CEMPAKA PUTIH  BARAT XIX RT.007/007	137	2024-05-08 12:22:17	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	0	\N
OP074083-060524-0163	RJJP080524-0483	07-40-83	JIHAN AR ROHIM, NY	KEPANITERAAN FKG	DU-45	F	2002-06-30	JL. BINTARA RAYA AA 99/4	137	2024-05-08 11:55:42	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	0	\N
OP079094-080524-0084	RJJP080524-0444	07-90-94	AGHIEL DZAKWAMUFID SUMUAL, TN	KEPANITERAAN FKG	GY-35	M	2001-06-23	JL. UTAN PANJANG III NO. 4	59	2024-05-08 11:14:45	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP079123-080524-0101	RJJP080524-0376	07-91-23	FARREL RAMADHAN, TN	KEPANITERAAN FKG	SQ-34	M	2001-12-04	JL CEMPAKA LAPANGAN TENIS NO 34 A	137	2024-05-08 10:26:41	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	0	\N
OP079100-080524-0070	RJJP080524-0336	07-91-00	NURUL WULANDARI, NY	KEPANITERAAN FKG	GY-34	F	1985-12-06	NAMBANGAN	59	2024-05-08 10:02:18	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP074575-080524-0083	RJJP080524-0251	07-45-75	CANTIKA PUTRI ALMIA, AN	KEPANITERAAN FKG	VI-15	F	2015-07-07	CEMPAKA PUTIH BARAT	58	2024-05-08 09:01:56	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP079104-080524-0079	RJJP080524-0247	07-91-04	KHAIRA PUTRI REZKY, AN	KEPANITERAAN FKG	VI-14	F	2018-05-21	JL. KAYU MANIS III BARU	58	2024-05-08 09:00:46	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP074560-080524-0079	RJJP080524-0196	07-45-60	AISYAH NURAILAH, AN	KEPANITERAAN FKG	VI-13	F	2018-06-22	JL. 25 DUREN SAWIT	58	2024-05-08 08:25:44	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP079093-080524-0174	RJJP080524-0184	07-90-93	AISHA HANAAN NABIILAH, AN	KEPANITERAAN FKG	VI-12	F	2013-04-23	JL. SUNGAI KAMPAR XI UJUNG NO. 35	58	2024-05-08 08:21:21	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
-	RKG080524-6876	-	Periapikal 1	KEPANITERAAN FKG	-	M	2024-05-08	-	10	2024-05-08 14:28:04	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
-	RKG080524-2232	-	periapikal 1	KEPANITERAAN FKG	-	M	2024-05-08	-	10	2024-05-08 14:32:09	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
OP076046-080524-0128	RJJP080524-0649	07-60-46	LARAS FAJRI NANDA WIDIISWA, NN	KEPANITERAAN FKG	GY-37	F	2002-03-07	JL Y NO 21 A	59	2024-05-08 15:31:01	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP073703-080524-0053	RJJP080524-0647	07-37-03	SEKAR DECITA ANANDA I, NN	KEPANITERAAN FKG	GY-36	F	2002-06-08	JL. KEMUNING 4B	59	2024-05-08 15:29:40	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP078431-080524-0132	RJJP080524-0653	07-84-31	CHAIRIAH BINTI MUHAMAD ZEIN, NY	KEPANITERAAN FKG	BR-8	F	1972-11-10	KOMPLEK KIMIA FARMA II	60	2024-05-08 15:34:38	Poli Gigi Spesialis Prostodonti	3859	drg. Bimo Rintoko, Sp.Pros	PERUSAHAAN	0	\N
OP075646-070524-0041	RJJP070524-0544	07-56-46	SHABRINA GHISANI MARZUKI, NN	KEPANITERAAN FKG	SQ-8	F	2002-06-21	JL. NEFTUNUS PRAYA BLOK  I 1 NO. 20	137	2024-05-07 13:27:31	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP078830-070524-0168	RJJP070524-0522	07-88-30	JERRI JULIDAR, TN	KEPANITERAAN FKG	SQ-7	M	2006-07-05	JL. KHATULISTIWA GG. BERINGIN 1	137	2024-05-07 12:49:31	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP073505-070524-0032	RJJP070524-0501	07-35-05	AULIA MAULIDA FITRIANI. NN	KEPANITERAAN FKG	SQ-6	F	2005-03-11	JL NURUL HUDA I NO 2\r\n002/015	137	2024-05-07 11:19:17	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP078987-070524-0108	RJJP070524-0469	07-89-87	ROBI TADRIANSAH, TN	KEPANITERAAN FKG	SQ-5	M	2005-04-25	SINGA PERBANGSA	137	2024-05-07 10:54:55	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP075934-060524-0138	RJJP060524-0575	07-59-34	SALWA MAWARDAH, NN	KEPANITERAAN FKG	DU-39	F	2006-09-15	JL KEMBANG VIII NO 12	137	2024-05-06 13:13:23	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP074083-060524-0163	RJJP060524-0531	07-40-83	JIHAN AR ROHIM, NY	KEPANITERAAN FKG	GY-44	F	2002-06-30	JL. BINTARA RAYA AA 99/4	59	2024-05-06 12:55:13	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP073195-060524-0069	RJJP060524-0411	07-31-95	FAIKA ZAHRA CHAIRUNISA, NN	KEPANITERAAN FKG	GY-43	F	2002-07-09	JL SPG VII	59	2024-05-06 10:50:50	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073108-060524-0063	RJJP060524-0405	07-31-08	SAHRI MUHAMAD RIZKY, TN 	KEPANITERAAN FKG	GY-42	M	2000-07-18	JL AK GANI 	59	2024-05-06 10:48:38	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP075934-060524-0057	RJJP060524-0399	07-59-34	SALWA MAWARDAH, NN	KEPANITERAAN FKG	DU-38	F	2006-09-15	JL KEMBANG VIII NO 12	137	2024-05-06 10:42:40	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP078799-060524-0065	RJJP060524-0284	07-87-99	WIROGO LISTYO DARYONO, SE, TN	KEPANITERAAN FKG	GY-40	M	1963-08-18	JL. Y NO.21 A	59	2024-05-06 09:23:47	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP078805-060524-0036	RJJP060524-0256	07-88-05	INDRA SYAPUTRA, TN	KEPANITERAAN FKG	GY-39	M	1998-03-31	JL YUNUS NO.51-C	59	2024-05-06 09:04:28	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073107-060524-0114	RJJP060524-0233	07-31-07	FARAH ALIFAH RAHAYU, NN	KEPANITERAAN FKG	GY-38	F	2002-08-02	JL KRIDA MANDALA II	59	2024-05-06 08:52:42	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP075535-030524-0097	RJJP030524-0465	07-55-35	IVO RESKY PRIMIGO, NN	KEPANITERAAN FKG	SQ-26	F	2001-07-21	JL. HALIMAH 	137	2024-05-03 11:37:27	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP075572-030524-0096	RJJP030524-0464	07-55-72	ATIKA RAHMA MINABARI, NY	KEPANITERAAN FKG	SQ-25	F	2000-12-18	JL CENDRAWASIH NO. 99	137	2024-05-03 11:35:52	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP052564-030524-0082	RJJP030524-0449	05-25-64	RAYYEN ALFRIAN JUNEANDRO,TN	KEPANITERAAN FKG	DU-44	M	2002-06-26	JL TITIHAN 6 BLOK HF 13 NO 14	137	2024-05-03 11:04:29	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP074083-030524-0079	RJJP030524-0446	07-40-83	JIHAN AR ROHIM, NY	KEPANITERAAN FKG	DU-43	F	2002-06-30	JL. BINTARA RAYA AA 99/4	137	2024-05-03 11:00:57	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP078432-030524-0145	RJJP030524-0215	07-84-32	DRA. ISWATUL CHASANAH, NY	KEPANITERAAN FKG	BR-6	F	1967-03-27	JL. Y NO.21 A	60	2024-05-03 08:32:56	Poli Gigi Spesialis Prostodonti	3859	drg. Bimo Rintoko, Sp.Pros	PERUSAHAAN	4	\N
OP076902-020524-0085	RJJP020524-0620	07-69-02	PUTRI AYU NURHADIZAH, NN	KEPANITERAAN FKG	DU-43	F	2002-10-04	BALIMATRAMAN NO. 6	137	2024-05-02 14:15:40	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP075572-020524-0139	RJJP020524-0546	07-55-72	ATIKA RAHMA MINABARI, NY	KEPANITERAAN FKG	DU-42	F	2000-12-18	JL CENDRAWASIH NO. 99	137	2024-05-02 11:53:53	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP073103-020524-0119	RJJP020524-0452	07-31-03	KARINA IVANA NARISWARI, NN	KEPANITERAAN FKG	GY-43	F	2002-01-25	KEBON PALA I	59	2024-05-02 10:30:03	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP078431-020524-0041	RJJP020524-0374	07-84-31	CHAIRIAH BINTI MUHAMAD ZEIN, NY	KEPANITERAAN FKG	GY-40	F	1972-11-10	KOMPLEK KIMIA FARMA II	59	2024-05-02 09:47:09	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP078431-020524-0041	RJJP020524-0340	07-84-31	CHAIRIAH BINTI MUHAMAD ZEIN, NY	KEPANITERAAN FKG	BR-10	F	1972-11-10	KOMPLEK KIMIA FARMA II	60	2024-05-02 09:25:08	Poli Gigi Spesialis Prostodonti	3859	drg. Bimo Rintoko, Sp.Pros	PERUSAHAAN	4	\N
-	RKG260524-8351	-	Panoramik	KEPANITERAAN FKG	-	M	2024-05-26	Cempaka putih	10	2024-05-26 18:17:24	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
OP074575-020524-0188	RJJP020524-0308	07-45-75	CANTIKA PUTRI ALMIA, AN	KEPANITERAAN FKG	VI-14	F	2015-07-07	CEMPAKA PUTIH BARAT	58	2024-05-02 09:08:21	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	4	\N
OP074181-020524-0107	RJJP020524-0219	07-41-81	AGNES SUKARSIH, NY	KEPANITERAAN FKG	BR-9	F	1960-07-27	JL. ANGIN SEJUK IV NO. 31	60	2024-05-02 08:23:51	Poli Gigi Spesialis Prostodonti	3859	drg. Bimo Rintoko, Sp.Pros	PERUSAHAAN	4	\N
OP076102-020524-0105	RJJP020524-0217	07-61-02	MUHAMMAD FATHIR ATTALLAH, AN	KEPANITERAAN FKG	VI-13	M	2014-10-09	JL. KEMUNING 4 B	58	2024-05-02 08:22:42	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	4	\N
OP074648-020524-0100	RJJP020524-0212	07-46-48	MUHAMMAD RIZAL, AN	KEPANITERAAN FKG	VI-12	M	2016-01-30	JL. CEMPAKA PUTIH TIMUR	58	2024-05-02 08:21:12	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	4	\N
OP076047-300424-0136	RJJP300424-0235	07-60-47	QANITA REGINA MAHARANI, NN	KEPANITERAAN FKG	GY-33	F	2002-09-01	KOMPLEK KIMIA FARMA II BLOK AG.9/8	59	2024-04-30 09:05:46	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP074575-300424-0121	RJJP300424-0232	07-45-75	CANTIKA PUTRI ALMIA, AN	KEPANITERAAN FKG	VI-12	F	2015-07-07	CEMPAKA PUTIH BARAT	58	2024-04-30 09:04:41	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	4	\N
OP073195-300424-0141	RJJP300424-0189	07-31-95	FAIKA ZAHRA CHAIRUNISA, NN	KEPANITERAAN FKG	GY-32	F	2002-07-09	JL SPG VII	59	2024-04-30 08:42:27	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073703-300424-0346	RJJP300424-0170	07-37-03	SEKAR DECITA ANANDA I, NN	KEPANITERAAN FKG	GY-31	F	2002-06-08	JL. KEMUNING 4B	59	2024-04-30 08:31:34	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP076046-290424-0151	RJJP290424-0374	07-60-46	LARAS FAJRI NANDA WIDIISWA, NN	KEPANITERAAN FKG	GY-35	F	2002-03-07	JL Y NO 21 A	59	2024-04-29 10:24:39	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP075535-250424-0172	RJJP250424-0386	07-55-35	IVO RESKY PRIMIGO, NN	KEPANITERAAN FKG	SQ-29	F	2001-07-21	JL. HALIMAH 	137	2024-04-25 10:02:23	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP074083-250424-0072	RJJP250424-0326	07-40-83	JIHAN AR ROHIM, NY	KEPANITERAAN FKG	GY-40	F	2002-06-30	JL. BINTARA RAYA AA 99/4	59	2024-04-25 09:26:28	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP075642-250424-0054	RJJP250424-0308	07-56-42	ALFAT FADILAH NUR, TN	KEPANITERAAN FKG	SQ-27	M	1996-10-10	DUSUN PAHLAWAN	137	2024-04-25 09:18:10	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP075572-240424-0213	RJJP240424-0576	07-55-72	ATIKA RAHMA MINABARI, NY	KEPANITERAAN FKG	SQ-29	F	2000-12-18	JL CENDRAWASIH NO. 99	137	2024-04-24 15:32:18	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP076902-240424-0107	RJJP240424-0386	07-69-02	PUTRI AYU NURHADIZAH, NN	KEPANITERAAN FKG	SQ-28	F	2002-10-04	BALIMATRAMAN NO. 6	137	2024-04-24 11:55:13	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
-	RKG080524-5991	-	-	KEPANITERAAN FKG	Nona Y	F	2024-05-08	Jl. X	10	2024-05-08 15:40:15	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
-	RKG080524-7020	-	Periapikal 1	KEPANITERAAN FKG	-	M	2024-05-08	-	10	2024-05-08 15:39:29	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
-	RKG080524-2580	-	periapikal 1	KEPANITERAAN FKG	-	F	2024-05-08	-	10	2024-05-08 15:45:34	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
-	RKG080524-7420	-	Periapikal 2	KEPANITERAAN FKG	-	F	2024-05-08	-	10	2024-05-08 15:46:32	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
-	RKG080524-3144	-	Ny.X	KEPANITERAAN FKG	-	F	2024-05-08	Jalan. Y	10	2024-05-08 15:39:27	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
-	RKG080524-8580	-	Periapikal 1	KEPANITERAAN FKG	-	F	2024-05-08	cempaka putih	10	2024-05-08 15:50:21	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
OP073195-080524-0092	RJJP080524-0672	07-31-95	FAIKA ZAHRA CHAIRUNISA, NN	KEPANITERAAN FKG	SQ-39	F	2002-07-09	JL SPG VII	137	2024-05-08 15:56:01	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	0	\N
-	RKG080524-3208	-	Periapikal 1	KEPANITERAAN FKG	-	F	2024-05-08	-	10	2024-05-08 16:12:29	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
OP079572-140524-0068	RJJP140524-0230	07-95-72	SUSETIYOWATI SE, NY	KEPANITERAAN FKG	GY-34	F	1969-03-14	JL. KRIDA MANDALA II NO. 77	59	2024-05-14 08:54:00	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP079568-140524-0045	RJJP140524-0206	07-95-68	MUHAMMAD IRFAN FACHRUL RODY, TN	KEPANITERAAN FKG	SQ-1	M	2000-06-08	PD. UNGU PERMAI BLOK AG7 / 2	137	2024-05-14 08:42:54	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	0	\N
OP073195-140524-0030	RJJP140524-0189	07-31-95	FAIKA ZAHRA CHAIRUNISA, NN	KEPANITERAAN FKG	GY-33	F	2002-07-09	JL SPG VII	59	2024-05-14 08:33:46	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP079562-140524-0026	RJJP140524-0185	07-95-62	EDWIN ROMEL, TN	KEPANITERAAN FKG	GY-32	M	1971-03-25	KOMPLEK KIMIA FARMA II BLOK AG.9/8	59	2024-05-14 08:32:12	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP078431-140524-0021	RJJP140524-0177	07-84-31	CHAIRIAH BINTI MUHAMAD ZEIN, NY	KEPANITERAAN FKG	GY-31	F	1972-11-10	KOMPLEK KIMIA FARMA II	59	2024-05-14 08:28:12	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP078799-140524-0261	RJJP140524-0136	07-87-99	WIROGO LISTYO DARYONO, SE, TN	KEPANITERAAN FKG	GY-30	M	1963-08-18	JL. Y NO.21 A	59	2024-05-14 08:03:44	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP079559-140524-0275	RJJP140524-0133	07-95-59	ANANDA AZZAHRA CHAERUNISA KASYIM, NY	KEPANITERAAN FKG	GY-29	F	2002-05-16	KEB BARU GG BUNTU I / 23	59	2024-05-14 08:02:38	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP078954-140524-0267	RJJP140524-0124	07-89-54	NAFISAH AMALIA, NY	KEPANITERAAN FKG	GY-28	F	2001-09-29	JL. KALIBARU BARAT VII	59	2024-05-14 07:58:25	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP079093-140524-0263	RJJP140524-0120	07-90-93	AISHA HANAAN NABIILAH, AN	KEPANITERAAN FKG	VI-10	F	2013-04-23	JL. SUNGAI KAMPAR XI UJUNG NO. 35	58	2024-05-14 07:56:45	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP045644-130524-0145	RJJP130524-0620	04-56-44	FRANKLIN PANGESTU, TN	KEPANITERAAN FKG	GY-50	M	1959-11-09	JL KELAPA NIAS X BLOK PD / 1	59	2024-05-13 14:59:01	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP045644-130524-0142	RJJP130524-0617	04-56-44	FRANKLIN PANGESTU, TN	KEPANITERAAN FKG	GY-49	M	1959-11-09	JL KELAPA NIAS X BLOK PD / 1	59	2024-05-13 14:52:59	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP045644-130524-0109	RJJP130524-0610	04-56-44	FRANKLIN PANGESTU, TN	KEPANITERAAN FKG	GY-48	M	1959-11-09	JL KELAPA NIAS X BLOK PD / 1	59	2024-05-13 14:46:34	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP045644-130524-0268	RJJP130524-0603	04-56-44	FRANKLIN PANGESTU, TN	KEPANITERAAN FKG	GY-47	M	1959-11-09	JL KELAPA NIAS X BLOK PD / 1	59	2024-05-13 14:40:16	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP045644-130524-0257	RJJP130524-0592	04-56-44	FRANKLIN PANGESTU, TN	KEPANITERAAN FKG	GY-46	M	1959-11-09	JL KELAPA NIAS X BLOK PD / 1	59	2024-05-13 14:32:57	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP045644-130524-0075	RJJP130524-0581	04-56-44	FRANKLIN PANGESTU, TN	KEPANITERAAN FKG	GY-45	M	1959-11-09	JL KELAPA NIAS X BLOK PD / 1	59	2024-05-13 14:19:27	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP079450-130524-0135	RJJP130524-0561	07-94-50	PUTRA TRI JAYA WIRAYUDHA, TN	KEPANITERAAN FKG	GY-44	M	2001-02-14	BTN.GRIYA KADUAGUNG INDAH BLOK 	59	2024-05-13 13:50:30	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP074282-130524-0116	RJJP130524-0527	07-42-82	AGUSTINA B NIRAHUWA, NY	KEPANITERAAN FKG	GY-43	F	1963-12-12	JL MARDANI III	59	2024-05-13 13:11:18	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP074083-130524-0105	RJJP130524-0494	07-40-83	JIHAN AR ROHIM, NY	KEPANITERAAN FKG	DU-51	F	2002-06-30	JL. BINTARA RAYA AA 99/4	137	2024-05-13 12:22:09	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP075934-130524-0116	RJJP130524-0473	07-59-34	SALWA MAWARDAH, NN	KEPANITERAAN FKG	DU-50	F	2006-09-15	JL KEMBANG VIII NO 12	137	2024-05-13 11:52:48	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP075572-130524-0159	RJJP130524-0458	07-55-72	ATIKA RAHMA MINABARI, NY	KEPANITERAAN FKG	DU-49	F	2000-12-18	JL CENDRAWASIH NO. 99	137	2024-05-13 11:38:53	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP075934-130524-0241	RJJP130524-0455	07-59-34	SALWA MAWARDAH, NN	KEPANITERAAN FKG	DU-48	F	2006-09-15	JL KEMBANG VIII NO 12	137	2024-05-13 11:37:04	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP052564-130524-0236	RJJP130524-0450	05-25-64	RAYYEN ALFRIAN JUNEANDRO,TN	KEPANITERAAN FKG	DU-47	M	2002-06-26	JL TITIHAN 6 BLOK HF 13 NO 14	137	2024-05-13 11:33:50	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP076046-080524-0128	RJJP130524-0436	07-60-46	LARAS FAJRI NANDA WIDIISWA, NN	KEPANITERAAN FKG	GY-42	F	2002-03-07	JL Y NO 21 A	59	2024-05-13 11:21:20	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP079410-130524-0010	RJJP130524-0175	07-94-10	FIFI ARFIANI, NY	KEPANITERAAN FKG	DU-46	F	1979-03-28	JL. RAYA CENTEX	137	2024-05-13 08:51:10	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	0	\N
OP050397-100524-0222	RJJP100524-0470	05-03-97	AYU LESTARI, NN	KEPANITERAAN FKG	SQ-36	F	2004-03-23	DUSUN PELITA RT 005/001	137	2024-05-10 13:11:19	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP050475-100524-0219	RJJP100524-0467	05-04-75	SHAFA ADILLA PUTRI MAHESA, NN	KEPANITERAAN FKG	SQ-35	F	2003-05-27	JL PDAM PAM JAYA NO 21 RT 010/003	137	2024-05-10 13:09:15	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP079123-100524-0201	RJJP100524-0449	07-91-23	FARREL RAMADHAN, TN	KEPANITERAAN FKG	SQ-34	M	2001-12-04	JL CEMPAKA LAPANGAN TENIS NO 34 A	137	2024-05-10 12:49:35	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP079163-100524-0300	RJJP100524-0254	07-91-63	ANINDITA VALENT SUGIANTO, AN	KEPANITERAAN FKG	DU-46	F	2012-02-22	BEBEDAHAN	137	2024-05-10 09:04:31	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP045644-150524-0327	RJJP150524-0563	04-56-44	FRANKLIN PANGESTU, TN	KEPANITERAAN FKG	GY-37	M	1959-11-09	JL KELAPA NIAS X BLOK PD / 1	59	2024-05-15 14:24:00	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP074575-150524-0172	RJJP150524-0495	07-45-75	CANTIKA PUTRI ALMIA, AN	KEPANITERAAN FKG	VI-16	F	2015-07-07	CEMPAKA PUTIH BARAT	58	2024-05-15 13:31:19	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP045644-150524-0034	RJJP150524-0453	04-56-44	FRANKLIN PANGESTU, TN	KEPANITERAAN FKG	GY-36	M	1959-11-09	JL KELAPA NIAS X BLOK PD / 1	59	2024-05-15 12:48:22	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP079094-150524-0031	RJJP150524-0450	07-90-94	AGHIEL DZAKWAMUFID SUMUAL, TN	KEPANITERAAN FKG	GY-35	M	2001-06-23	JL. UTAN PANJANG III NO. 4	59	2024-05-15 12:44:50	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP074181-150524-0362	RJJP150524-0398	07-41-81	AGNES SUKARSIH, NY	KEPANITERAAN FKG	BR-10	F	1960-07-27	JL. ANGIN SEJUK IV NO. 31	60	2024-05-15 11:36:20	Poli Gigi Spesialis Prostodonti	3859	drg. Bimo Rintoko, Sp.Pros	PERUSAHAAN	0	\N
OP078987-150524-0314	RJJP150524-0317	07-89-87	ROBI TADRIANSAH, TN	KEPANITERAAN FKG	SQ-31	M	2005-04-25	SINGA PERBANGSA	137	2024-05-15 10:30:49	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP079568-150524-0302	RJJP150524-0305	07-95-68	MUHAMMAD IRFAN FACHRUL RODY, TN	KEPANITERAAN FKG	SQ-30	M	2000-06-08	PD. UNGU PERMAI BLOK AG7 / 2	137	2024-05-15 10:21:20	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP079778-150524-0274	RJJP150524-0277	07-97-78	ERYN NUR ZHAFIROH, AN	KEPANITERAAN FKG	VI-14	F	2015-12-13	DK. SABRANG	58	2024-05-15 10:05:12	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP079784-150524-0313	RJJP150524-0264	07-97-84	ZIAS AT TIRMIDZI, AN	KEPANITERAAN FKG	VI-12	M	2015-11-26	RUSUN PINUS ELOK BLOK A4 LT.4/09	58	2024-05-15 09:57:08	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP079795-150524-0316	RJJP150524-0267	07-97-95	VARISHA HUWAIDA RAMADHINA, AN	KEPANITERAAN FKG	VI-13	F	2018-06-05	JL. HARAPAN MULIA VI NO. 18	58	2024-05-15 09:56:52	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	4	\N
OP074560-150524-0282	RJJP150524-0116	07-45-60	AISYAH NURAILAH, AN	KEPANITERAAN FKG	VI-10	F	2018-06-22	JL. 25 DUREN SAWIT	58	2024-05-15 08:20:51	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP074648-150524-0267	RJJP150524-0101	07-46-48	MUHAMMAD RIZAL, AN	KEPANITERAAN FKG	VI-9	M	2016-01-30	JL. CEMPAKA PUTIH TIMUR	58	2024-05-15 08:00:33	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	4	\N
OP073193-160524-0094	RJJP160524-0323	07-31-93	DINDA KANIA LARASATI, NN	KEPANITERAAN FKG	GY-40	F	2002-07-27	BLOK R GG II / 63	59	2024-05-16 09:53:33	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP075646-160524-0016	RJJP160524-0229	07-56-46	SHABRINA GHISANI MARZUKI, NN	KEPANITERAAN FKG	SQ-27	F	2002-06-21	JL. NEFTUNUS PRAYA BLOK  I 1 NO. 20	137	2024-05-16 08:47:48	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	0	\N
OP079568-160524-0298	RJJP160524-0218	07-95-68	MUHAMMAD IRFAN FACHRUL RODY, TN	KEPANITERAAN FKG	SQ-26	M	2000-06-08	PD. UNGU PERMAI BLOK AG7 / 2	137	2024-05-16 08:43:52	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	0	\N
OP074282-160524-0284	RJJP160524-0204	07-42-82	AGUSTINA B NIRAHUWA, NY	KEPANITERAAN FKG	DU-43	F	1963-12-12	JL MARDANI III	137	2024-05-16 08:37:40	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	0	\N
-	RKG160524-3183	-	Periapikal 1	KEPANITERAAN FKG	-	M	2024-05-16	-	10	2024-05-16 10:59:05	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
OP073193-210524-0022	RJJP210524-0459	07-31-93	DINDA KANIA LARASATI, NN	KEPANITERAAN FKG	GY-39	F	2002-07-27	BLOK R GG II / 63	59	2024-05-21 10:58:54	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP074648-210524-0056	RJJP210524-0422	07-46-48	MUHAMMAD RIZAL, AN	KEPANITERAAN FKG	VI-15	M	2016-01-30	JL. CEMPAKA PUTIH TIMUR	58	2024-05-21 10:23:30	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP079795-210524-0011	RJJP210524-0364	07-97-95	VARISHA HUWAIDA RAMADHINA, AN	KEPANITERAAN FKG	VI-14	F	2018-06-05	JL. HARAPAN MULIA VI NO. 18	58	2024-05-21 09:53:24	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP074648-210524-0143	RJJP210524-0345	07-46-48	MUHAMMAD RIZAL, AN	KEPANITERAAN FKG	VI-13	M	2016-01-30	JL. CEMPAKA PUTIH TIMUR	58	2024-05-21 09:39:06	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	4	\N
OP079778-210524-0079	RJJP210524-0287	07-97-78	ERYN NUR ZHAFIROH, AN	KEPANITERAAN FKG	VI-12	F	2015-12-13	DK. SABRANG	58	2024-05-21 09:07:42	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP072374-210524-0122	RJJP210524-0222	07-23-74	JENNITA ADZURA SANI. AN	KEPANITERAAN FKG	VI-11	F	2015-04-08	CEMPAKA PUTIH BARAT III NO. 22	58	2024-05-21 08:38:07	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP079559-210524-0305	RJJP210524-0202	07-95-59	ANANDA AZZAHRA CHAERUNISA KASYIM, NY	KEPANITERAAN FKG	GY-38	F	2002-05-16	KEB BARU GG BUNTU I / 23	59	2024-05-21 08:27:04	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP079562-210524-0296	RJJP210524-0193	07-95-62	EDWIN ROMEL, TN	KEPANITERAAN FKG	GY-37	M	1971-03-25	KOMPLEK KIMIA FARMA II BLOK AG.9/8	59	2024-05-21 08:24:28	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP079784-220524-0157	RJJP220524-0275	07-97-84	ZIAS AT TIRMIDZI, AN	KEPANITERAAN FKG	VI-12	M	2015-11-26	RUSUN PINUS ELOK BLOK A4 LT.4/09	58	2024-05-22 09:43:41	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP080384-220524-0178	RJJP220524-0213	08-03-84	FARISYAH ALFARABI, AN	KEPANITERAAN FKG	VI-10	M	2014-12-29	JL. JENGKI CIPINANG ASEM NO. 47	58	2024-05-22 09:04:10	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP052460-240524-0270	RJJP240524-0353	05-24-60	shafa adilla putri mahesa	KEPANITERAAN FKG	SQ-31	F	2003-05-27	Jl. pam jaya no.21a	137	2024-05-24 10:16:49	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP050397-240524-0268	RJJP240524-0351	05-03-97	AYU LESTARI, NN	KEPANITERAAN FKG	SQ-30	F	2004-03-23	DUSUN PELITA RT 005/001	137	2024-05-24 10:14:57	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP079568-210524-0081	RJJP220524-0701	07-95-68	MUHAMMAD IRFAN FACHRUL RODY, TN	KEPANITERAAN FKG	DU-42	M	2000-06-08	PD. UNGU PERMAI BLOK AG7 / 2	137	2024-05-22 17:26:15	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP079568-210524-0081	RJJP220524-0605	07-95-68	MUHAMMAD IRFAN FACHRUL RODY, TN	KEPANITERAAN FKG	DU-41	M	2000-06-08	PD. UNGU PERMAI BLOK AG7 / 2	137	2024-05-22 14:59:24	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP074083-220524-0104	RJJP220524-0597	07-40-83	JIHAN AR ROHIM, NY	KEPANITERAAN FKG	DU-40	F	2002-06-30	JL. BINTARA RAYA AA 99/4	137	2024-05-22 14:46:24	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP075934-220524-0172	RJJP220524-0562	07-59-34	SALWA MAWARDAH, NN	KEPANITERAAN FKG	SQ-37	F	2006-09-15	JL KEMBANG VIII NO 12	137	2024-05-22 13:47:47	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP079667-220524-0355	RJJP220524-0547	07-96-67	VIDIYAH NURUL RAHMA, NY	KEPANITERAAN FKG	GY-26	F	2002-07-07	JL. WADAS RAYA	59	2024-05-22 13:39:01	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP080023-220524-0167	RJJP220524-0505	08-00-23	SUHARTATI, NY	KEPANITERAAN FKG	BR-21	F	1963-06-10	VILLA MEUTIA KIRANA JL. MEUTIA KIRANA BLOK C1/17	60	2024-05-22 13:01:14	Poli Gigi Spesialis Prostodonti	3859	drg. Bimo Rintoko, Sp.Pros	PERUSAHAAN	4	\N
OP080182-220524-0229	RJJP220524-0497	08-01-82	GOTTMEN.T, TN	KEPANITERAAN FKG	DU-38	M	1969-10-15	JL. HALIMAH	137	2024-05-22 12:54:45	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP075646-220524-0228	RJJP220524-0496	07-56-46	SHABRINA GHISANI MARZUKI, NN	KEPANITERAAN FKG	SQ-36	F	2002-06-21	JL. NEFTUNUS PRAYA BLOK  I 1 NO. 20	137	2024-05-22 12:53:37	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP079568-210524-0081	RJJP220524-0492	07-95-68	MUHAMMAD IRFAN FACHRUL RODY, TN	KEPANITERAAN FKG	GY-25	M	2000-06-08	PD. UNGU PERMAI BLOK AG7 / 2	59	2024-05-22 12:52:21	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP074282-220524-0037	RJJP220524-0477	07-42-82	AGUSTINA B NIRAHUWA, NY	KEPANITERAAN FKG	BR-20	F	1963-12-12	JL MARDANI III	60	2024-05-22 12:37:22	Poli Gigi Spesialis Prostodonti	3859	drg. Bimo Rintoko, Sp.Pros	PERUSAHAAN	4	\N
OP079568-210524-0081	RJJP210524-0503	07-95-68	MUHAMMAD IRFAN FACHRUL RODY, TN	KEPANITERAAN FKG	GY-41	M	2000-06-08	PD. UNGU PERMAI BLOK AG7 / 2	59	2024-05-21 12:21:16	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP079568-210524-0081	RJJP210524-0500	07-95-68	MUHAMMAD IRFAN FACHRUL RODY, TN	KEPANITERAAN FKG	SQ-3	M	2000-06-08	PD. UNGU PERMAI BLOK AG7 / 2	137	2024-05-21 12:16:15	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP079568-210524-0016	RJJP210524-0487	07-95-68	MUHAMMAD IRFAN FACHRUL RODY, TN	KEPANITERAAN FKG	SQ-2	M	2000-06-08	PD. UNGU PERMAI BLOK AG7 / 2	137	2024-05-21 11:44:23	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP079568-210524-0014	RJJP210524-0485	07-95-68	MUHAMMAD IRFAN FACHRUL RODY, TN	KEPANITERAAN FKG	SQ-1	M	2000-06-08	PD. UNGU PERMAI BLOK AG7 / 2	137	2024-05-21 11:39:55	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP074282-160524-0284	RJJP200524-0524	07-42-82	AGUSTINA B NIRAHUWA, NY	KEPANITERAAN FKG	GY-40	F	1963-12-12	JL MARDANI III	59	2024-05-20 11:25:51	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP079675-200524-0092	RJJP200524-0504	07-96-75	A.ZHAFIR AFGHANI, TN	KEPANITERAAN FKG	GY-39	M	2001-10-17	JL. MANGGAR GG 5 BLOK Y	59	2024-05-20 11:11:49	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP079689-200524-0148	RJJP200524-0406	07-96-89	RIFKY SETIYA YUDIKA. TN	KEPANITERAAN FKG	GY-37	M	2002-08-14	JAKARTA	59	2024-05-20 10:07:29	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP076047-200524-0333	RJJP200524-0402	07-60-47	QANITA REGINA MAHARANI, NN	KEPANITERAAN FKG	GY-36	F	2002-09-01	KOMPLEK KIMIA FARMA II BLOK AG.9/8	59	2024-05-20 10:06:01	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073193-200524-0108	RJJP200524-0245	07-31-93	DINDA KANIA LARASATI, NN	KEPANITERAAN FKG	GY-33	F	2002-07-27	BLOK R GG II / 63	59	2024-05-20 08:48:25	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP080182-200524-0084	RJJP200524-0221	08-01-82	GOTTMEN.T, TN	KEPANITERAAN FKG	DU-38	M	1969-10-15	JL. HALIMAH	137	2024-05-20 08:36:59	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP079123-170524-0217	RJJP170524-0491	07-91-23	FARREL RAMADHAN, TN	KEPANITERAAN FKG	SQ-36	M	2001-12-04	JL CEMPAKA LAPANGAN TENIS NO 34 A	137	2024-05-17 14:55:48	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP076902-170524-0261	RJJP170524-0392	07-69-02	PUTRI AYU NURHADIZAH, NN	KEPANITERAAN FKG	SQ-35	F	2002-10-04	BALIMATRAMAN NO. 6	137	2024-05-17 12:46:47	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP073236-170524-0259	RJJP170524-0390	07-32-36	NADZWA RETHA YUSNITA, NN	KEPANITERAAN FKG	DU-42	F	2005-03-03	JL CEMPAKA INDAH NO 13	137	2024-05-17 12:43:59	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP078830-170524-0097	RJJP170524-0386	07-88-30	JERRI JULIDAR, TN	KEPANITERAAN FKG	SQ-34	M	2006-07-05	JL. KHATULISTIWA GG. BERINGIN 1	137	2024-05-17 12:29:40	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP079123-170524-0159	RJJP170524-0362	07-91-23	FARREL RAMADHAN, TN	KEPANITERAAN FKG	SQ-33	M	2001-12-04	JL CEMPAKA LAPANGAN TENIS NO 34 A	137	2024-05-17 11:40:20	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP080023-170524-0109	RJJP170524-0196	08-00-23	SUHARTATI, NY	KEPANITERAAN FKG	BR-8	F	1963-06-10	VILLA MEUTIA KIRANA JL. MEUTIA KIRANA BLOK C1/17	60	2024-05-17 08:50:20	Poli Gigi Spesialis Prostodonti	3859	drg. Bimo Rintoko, Sp.Pros	PERUSAHAAN	4	\N
OP079163-170524-0125	RJJP170524-0146	07-91-63	ANINDITA VALENT SUGIANTO, AN	KEPANITERAAN FKG	DU-41	F	2012-02-22	BEBEDAHAN	137	2024-05-17 08:27:13	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP073103-160524-0279	RJJP160524-0488	07-31-03	KARINA IVANA NARISWARI, NN	KEPANITERAAN FKG	GY-42	F	2002-01-25	KEBON PALA I	59	2024-05-16 14:54:39	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP079568-160524-0253	RJJP160524-0443	07-95-68	MUHAMMAD IRFAN FACHRUL RODY, TN	KEPANITERAAN FKG	SQ-31	M	2000-06-08	PD. UNGU PERMAI BLOK AG7 / 2	137	2024-05-16 13:24:29	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP079100-160524-0244	RJJP160524-0434	07-91-00	NURUL WULANDARI, NY	KEPANITERAAN FKG	GY-41	F	1985-12-06	NAMBANGAN	59	2024-05-16 12:59:16	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP073195-160524-0240	RJJP160524-0430	07-31-95	FAIKA ZAHRA CHAIRUNISA, NN	KEPANITERAAN FKG	SQ-30	F	2002-07-09	JL SPG VII	137	2024-05-16 12:49:08	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP075646-160524-0255	RJJP160524-0428	07-56-46	SHABRINA GHISANI MARZUKI, NN	KEPANITERAAN FKG	SQ-29	F	2002-06-21	JL. NEFTUNUS PRAYA BLOK  I 1 NO. 20	137	2024-05-16 12:48:08	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP079675-140524-0185	RJUL140524-0016	07-96-75	A.ZHAFIR AFGHANI, TN	KEPANITERAAN FKG	SB-14	M	2001-10-17	JL. MANGGAR GG 5 BLOK Y	59	2024-05-14 17:30:36	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP076046-140524-0186	RJJP140524-0582	07-60-46	LARAS FAJRI NANDA WIDIISWA, NN	KEPANITERAAN FKG	GY-37	F	2002-03-07	JL Y NO 21 A	59	2024-05-14 14:57:51	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP079667-140524-0036	RJJP140524-0515	07-96-67	VIDIYAH NURUL RAHMA, NY	KEPANITERAAN FKG	GY-36	F	2002-07-07	JL. WADAS RAYA	59	2024-05-14 13:53:21	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP079568-140524-0045	RJJP140524-0506	07-95-68	MUHAMMAD IRFAN FACHRUL RODY, TN	KEPANITERAAN FKG	DU-46	M	2000-06-08	PD. UNGU PERMAI BLOK AG7 / 2	137	2024-05-14 13:42:11	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
OP073505-140524-0088	RJJP140524-0441	07-35-05	AULIA MAULIDA FITRIANI. NN	KEPANITERAAN FKG	SQ-2	F	2005-03-11	JL NURUL HUDA I NO 2\r\n002/015	137	2024-05-14 11:36:45	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
OP078805-140524-0060	RJJP140524-0430	07-88-05	INDRA SYAPUTRA, TN	KEPANITERAAN FKG	GY-35	M	1998-03-31	JL YUNUS NO.51-C	59	2024-05-14 11:22:01	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP076902-140524-0118	RJJP140524-0283	07-69-02	PUTRI AYU NURHADIZAH, NN	KEPANITERAAN FKG	DU-43	F	2002-10-04	BALIMATRAMAN NO. 6	137	2024-05-14 09:23:58	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	4	\N
-	RKG250524-2562	-	Periapikal 1	KEPANITERAAN FKG	-	M	2024-05-25	Cempaka Putih	10	2024-05-25 20:58:37	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
-	RKG250524-2836	-	Oklusal	KEPANITERAAN FKG	-	M	2024-05-25	-	10	2024-05-25 22:15:15	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
-	RKG250524-1898	-	Periapikal 1	KEPANITERAAN FKG	-	F	2024-05-25	Cempaka putih	10	2024-05-25 22:46:58	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
-	RKG250524-1348	-	Periapikal 2	KEPANITERAAN FKG	-	F	2024-05-25	Cempaka putih	10	2024-05-25 23:47:26	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
-	RKG260524-9458	-	Periapikal 3	KEPANITERAAN FKG	-	F	2024-05-26	Cempaka putih	10	2024-05-26 00:09:53	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
01	RKG270524-4986	rkg 1	Tn.x / Periapikal intepretasi rkg 1	KEPANITERAAN FKG	1	M	1983-06-08	Bosnia, Amerika	10	2024-05-27 07:56:03	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
02	RKG270524-4207	rkg 1	Nn. Nabila / Video Periapikal	KEPANITERAAN FKG	02	F	2020-07-09	Cempaka Putih	10	2024-05-27 08:00:10	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
03	RKG270524-8802	rkg 2	Nn. N/ Periapikal Intepretasi rkg 2	KEPANITERAAN FKG	3	F	2006-02-08	Thailand	10	2024-05-27 08:33:49	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
04	RKG270524-8126	rkg 2	Ny.X/ Periapikal Intepretasi rkg 2	KEPANITERAAN FKG	4	F	2024-05-27	Jakarta	10	2024-05-27 08:39:22	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
05	RKG270524-9246	rkg 2	Tn. Y/ Panoramic Intepretasi rkg 2	KEPANITERAAN FKG	5	M	1994-07-05	Indonesia	10	2024-05-27 08:44:48	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
-	RKG270524-2501	-	Panoramik	KEPANITERAAN FKG	-	M	2024-05-27	Cempaka putih	10	2024-05-27 09:00:31	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
-	RKG270524-3462	-	Video oklusal	KEPANITERAAN FKG	-	M	2024-05-27	Cempaka putih	10	2024-05-27 09:44:51	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
06	RKG270524-9157	rkg 2	Ny. B	KEPANITERAAN FKG	6	F	2024-05-27	Korea Selatan	10	2024-05-27 11:26:58	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
01	RKG270524-2493	RKG 1	Ny. X	KEPANITERAAN FKG	01	F	2024-05-27	Korea	10	2024-05-27 11:39:39	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
1	RKG270524-9098	RKG 1	Tn. B	KEPANITERAAN FKG	1	M	2024-05-27	Indonesia	10	2024-05-27 11:43:21	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
1	RKG270524-4020	RKG 1	Nn.X/Interpretasi Periapikal 1	KEPANITERAAN FKG	1	M	2009-05-27	RSGM Eastman, London	10	2024-05-27 11:56:14	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
2	RKG270524-4948	2	Nn. B	KEPANITERAAN FKG	2	F	2024-05-27	Indonesia	10	2024-05-27 12:15:28	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
2	RKG270524-3748	2	Nn. B	KEPANITERAAN FKG	RKG 1	F	2024-05-27	Indonesia	10	2024-05-27 12:27:03	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
2	RKG270524-4409	RKG 1	Nn. B	KEPANITERAAN FKG	2	F	2024-05-27	Indonesia	10	2024-05-27 12:27:59	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
3	RKG270524-4013	RKG 1	Nn. B	KEPANITERAAN FKG	3	F	2024-05-27	Indonesia	10	2024-05-27 12:36:56	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
2	RKG270524-1012	RKG 1	Nn.Y	KEPANITERAAN FKG	2	F	2007-05-27	RSGM Eastman, London	10	2024-05-27 12:30:26	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
4	RKG270524-5998	RKG 1	Tn. B	KEPANITERAAN FKG	4	M	2024-05-27	Eropa	10	2024-05-27 13:09:37	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
1	RKG270524-9220	RKG 2	Nn. B	KEPANITERAAN FKG	1	F	2024-05-27	Brazil	10	2024-05-27 13:23:42	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
2	RKG270524-2456	RKG 2	Ny. B	KEPANITERAAN FKG	2	F	2024-05-27	Indonesia	10	2024-05-27 13:35:52	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
3	RKG270524-9704	RKG 2	Nn. B	KEPANITERAAN FKG	3	F	2024-05-27	Indonesia	10	2024-05-27 13:49:31	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
4	RKG270524-1238	RKG 2	Tn. B	KEPANITERAAN FKG	4	M	2024-05-27	Indonesia	10	2024-05-27 14:07:01	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
01	RKG270524-5327	02	ny. X	KEPANITERAAN FKG	01	F	2024-05-27	jl. raden fatah	10	2024-05-27 14:17:04	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
01	RKG270524-6487	01	Tn. X	KEPANITERAAN FKG	01	M	2024-05-27	Jl. India benua antartika	10	2024-05-27 14:25:14	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
01	RKG270524-6007	RKG 1	Ny.Y	KEPANITERAAN FKG	01	F	2024-05-27	Jl. Cempaka Putih	10	2024-05-27 14:45:07	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
3	RKG270524-5785	RKG 1	Tn.X/Interpretasi Periapikal 1	KEPANITERAAN FKG	3	M	1971-05-27	RSGM Universitas Andalas, Sumatera Barat	10	2024-05-27 14:38:32	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
-	RKG270524-6950	-	Periapikal 1	KEPANITERAAN FKG	-	M	2024-05-27	-	10	2024-05-27 14:46:47	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
01	RKG270524-4532	RKG 1	Ny. XY	KEPANITERAAN FKG	01	F	2024-05-27	jl. Raden fatah	10	2024-05-27 15:09:37	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
01	RKG270524-2156	01	NY. X	KEPANITERAAN FKG	01	F	2000-05-27	Korea	10	2024-05-27 15:47:26	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
01	RKG270524-8949	RKG 1	Ny. X	KEPANITERAAN FKG	01	F	2000-05-27	Korea	10	2024-05-27 15:55:11	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
4	RKG270524-4688	RKG 1	An.X/Interpretasi Panoramik 1	KEPANITERAAN FKG	4	M	2008-05-27	Rumah Sakit Gigi Universitas Nasional Kyungpook	10	2024-05-27 17:14:07	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
5	RKG270524-4942	RKG 2	Ny.Y	KEPANITERAAN FKG	5	F	2002-05-27	South-east Iran	10	2024-05-27 17:33:42	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
6	RKG270524-3117	RKG 2	Ny.A/Interpretasi Periapikal 2	KEPANITERAAN FKG	6	F	1999-05-27	Mathura, Uttar Pradesh-India	10	2024-05-27 17:44:31	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
7	RKG270524-6417	RKG 2	An.B/Interpretasi Oklusal Rkg 2	KEPANITERAAN FKG	7	F	2012-05-27	Universitas Indonesia, Jakarta-Indonesia	10	2024-05-27 18:07:58	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
8	RKG270524-2704	RKG 2	Ny.C/Interpretasi Panoramik Rkg 2	KEPANITERAAN FKG	8	F	1993-05-27	Fakultas Kedokteran Gigi Universitas Sao Paulo-Brazil	10	2024-05-27 18:26:20	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
9	RKG270524-2953	RKG 2	Ny.D/Interpretasi Periapikal Rkg 2	KEPANITERAAN FKG	9	F	1995-05-27	São Paulo, Brazil	10	2024-05-27 18:43:47	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
-	RKG270524-1749	RKG 2	Periapikal 2	KEPANITERAAN FKG	-	M	2024-05-27	Cempaka putih	10	2024-05-27 22:19:42	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
02	RKG270524-3812	RKG 1	Nn. X	KEPANITERAAN FKG	02	F	2012-05-27	India	10	2024-05-27 22:39:25	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
01	RKG270524-9401	RKG 1	Salwa	KEPANITERAAN FKG	01	F	2024-05-27	Jl. Cempaka Baru IV no. 5	10	2024-05-27 23:11:34	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
02	RKG270524-3875	RKG 1	Rian	KEPANITERAAN FKG	02	M	2024-05-27	Jl. Rambutan V no. 8	10	2024-05-27 23:21:26	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
-	RKG280524-9784	-	An. X	KEPANITERAAN FKG	01	F	2009-05-28	Jl. C	10	2024-04-05 14:00:00	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
05	RKG280524-9917	rkg 1	Nn. P/ periapikal intepretasi rkg 1	KEPANITERAAN FKG	5	F	2024-05-28	Jakarta Barat	10	2024-05-28 07:37:54	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
06	RKG280524-1846	rkg 1	Tn. K/ Panoramic Intepretasi	KEPANITERAAN FKG	6	M	2007-02-13	Korea Selatan	10	2024-05-28 07:49:39	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
07	RKG280524-9347	rkg 2	Nn. B/ periapikal intepretasi	KEPANITERAAN FKG	07	F	2001-01-11	Jakarta	10	2024-05-28 07:57:12	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
08	RKG280524-4908	rkg 2	Ny. U/ oklusal intepretasi rkg 2	KEPANITERAAN FKG	8	F	1987-06-04	Depok	10	2024-05-28 08:07:47	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
03	RKG280524-9613	RKG 1	Viola	KEPANITERAAN FKG	03	F	2001-05-28	Jl. Venus Raya blok A/4	10	2024-05-28 08:41:57	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
5	RKG280524-5552	RKG 2	Ny. B	KEPANITERAAN FKG	5	F	2024-05-28	Amerika	10	2024-05-28 08:46:46	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
1	RKG280524-1310	1	RKG 1: Periapikal 1 : Tn. A	KEPANITERAAN FKG	1	F	2002-05-28	Jl. A	10	2024-05-28 08:51:23	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
2	RKG280524-5892	2	RKG 1 : Periapikal 2 : Ny. B	KEPANITERAAN FKG	2	F	2002-05-28	Jl.B	10	2024-05-28 08:53:45	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
3	RKG280524-9586	3	RKG 1 : Periapikal 3 : Tn. C	KEPANITERAAN FKG	3	M	2002-05-28	Jl. C	10	2024-05-28 08:55:03	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
04	RKG280524-4415	RKG 1	Haikal	KEPANITERAAN FKG	04	M	2024-05-28	Jl. Jambu no 7	10	2024-05-28 08:56:23	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
4	RKG280524-8082	4	RKG 1 : Periapikal : Tn. D	KEPANITERAAN FKG	4	M	2002-05-28	Jl.D	10	2024-05-28 08:56:47	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
5	RKG280524-5722	5	RKG 1 : Video Periapikal : Case report : An X dan An Y	KEPANITERAAN FKG	5	F	2002-05-28	Jl. X	10	2024-05-28 08:58:13	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
03	RKG280524-2867	RKG 1	Tn. T	KEPANITERAAN FKG	03	M	1976-05-28	Thailand	10	2024-05-28 09:00:16	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
6	RKG280524-9287	6	RKG 2 : Periapikal : Tn. E	KEPANITERAAN FKG	6	M	2002-05-28	Jl. E	10	2024-05-28 09:03:41	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
7	RKG280524-7145	7	RKG 2 : Periapikal 7 : Ny. F	KEPANITERAAN FKG	7	F	2002-05-28	Jl. F	10	2024-05-28 09:06:00	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
8	RKG280524-8860	8	RKG 2 : Panoramik 2 : Tn. G	KEPANITERAAN FKG	8	M	2002-05-28	Jl. G	10	2024-05-28 09:06:56	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
01	RKG280524-9266	RKG 1	Ny. X/ Periapikal/ drg. Resky	KEPANITERAAN FKG	01	F	2024-03-28	Jl. X	10	2024-03-28 09:03:00	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
9	RKG280524-6704	9	RKG 2 : Periapikal 9 : Tn. H	KEPANITERAAN FKG	9	M	2002-05-28	Jl. H	10	2024-05-28 09:08:10	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
10	RKG280524-4647	10	RKG 2 : Oklusal 1 : Ny. I	KEPANITERAAN FKG	10	F	2002-05-28	Jl. I	10	2024-05-28 09:09:13	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
11	RKG280524-5411	11	RKG 2 : Video Oklusal	KEPANITERAAN FKG	11	M	2002-05-28	-	10	2024-05-28 09:10:27	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
001	RKG280524-5692	RKG 1	NY. AB	KEPANITERAAN FKG	001	F	2024-05-28	jl. Cempaka Putih	10	2024-05-28 09:11:35	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
01	RKG280524-8295	RKG 2	Hani	KEPANITERAAN FKG	02	F	2024-05-28	Jl. Kemanggisan V no. 6	10	2024-05-28 09:10:34	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
2	RKG280524-4815	02	Tn. X / Periapikal/ drg. Resky	KEPANITERAAN FKG	2	M	1997-05-28	jl. ivo	10	2024-03-28 09:24:00	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
02	RKG280524-9029	RKG 2	Rivan	KEPANITERAAN FKG	02	M	2024-05-28	Jl. Cemara III No. 7	10	2024-05-28 09:19:15	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
-	RKG280524-4618	-	Periapikal 1	KEPANITERAAN FKG	-	M	2024-05-28	-	10	2024-05-28 09:50:59	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
03	RKG280524-3054	RKG 2	Tn. X	KEPANITERAAN FKG	-	M	2024-05-28	Jl. Cempaka tengah V No. 20	10	2024-05-28 09:55:34	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
04	RKG280524-6416	RKG 2	Tn X	KEPANITERAAN FKG	04	M	2024-05-28	Jl. Cempaka baru No. 6	10	2024-05-28 10:06:28	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
-	RKG280524-5401	RKG 1	NY. BA	KEPANITERAAN FKG	-	F	2024-05-28	jl. kalimalang	10	2024-05-28 11:57:04	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
-	RKG280524-5037	RKG 2	Mr. B	KEPANITERAAN FKG	-	M	2024-05-28	jl. bekasi raya	10	2024-05-28 12:00:49	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
OP052564-280524-0277	RJJP280524-0480	05-25-64	RAYYEN ALFRIAN JUNEANDRO,TN	KEPANITERAAN FKG	GY-33	M	2002-06-26	JL TITIHAN 6 BLOK HF 13 NO 14	59	2024-05-28 12:19:01	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
09	RKG280524-4835	rkg 2	Nn. Mutia/ Video Oklusal	KEPANITERAAN FKG	-	F	2024-05-28	Jakarta	10	2024-05-28 12:32:59	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
OP075535-280524-0086	RJJP280524-0533	07-55-35	IVO RESKY PRIMIGO, NN	KEPANITERAAN FKG	GY-34	F	2001-07-21	JL. HALIMAH 	59	2024-05-28 14:24:13	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
04	RKG280524-5313	RKG 1	Ny. X	KEPANITERAAN FKG	04	F	2024-05-28	Jakarta	10	2024-05-28 09:12:58	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
OP076902-280524-0099	RJJP280524-0546	07-69-02	PUTRI AYU NURHADIZAH, NN	KEPANITERAAN FKG	GY-35	F	2002-10-04	BALIMATRAMAN NO. 6	59	2024-05-28 14:47:41	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
01	RKG280524-6394	RKG 2	Nn. Y	KEPANITERAAN FKG	01	F	2024-05-28	Tangerang	10	2024-05-28 15:54:30	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
02	RKG280524-1605	RKG 2	Nn. x	KEPANITERAAN FKG	02	F	1995-05-28	Indonesia	10	2024-05-28 16:13:07	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
03	RKG280524-7796	RKG 2	Tn. J	KEPANITERAAN FKG	03	M	2002-11-15	Korea	10	2024-05-28 16:27:51	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
04	RKG280524-8549	RKG 2	Ny. Z	KEPANITERAAN FKG	04	F	2020-05-28	Japan	10	2024-05-28 17:17:39	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
05	RKG280524-5367	RKG 2	Tn. SJ	KEPANITERAAN FKG	05	M	2012-05-28	Australia	10	2024-05-28 17:25:52	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
OP075572-290524-0346	RJJP290524-0494	07-55-72	ATIKA RAHMA MINABARI, NY	KEPANITERAAN FKG	GY-23	F	2000-12-18	JL CENDRAWASIH NO. 99	59	2024-05-29 15:12:35	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP075646-290524-0345	RJJP290524-0493	07-56-46	SHABRINA GHISANI MARZUKI, NN	KEPANITERAAN FKG	GY-22	F	2002-06-21	JL. NEFTUNUS PRAYA BLOK  I 1 NO. 20	59	2024-05-29 15:11:39	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP075535-290524-0344	RJJP290524-0492	07-55-35	IVO RESKY PRIMIGO, NN	KEPANITERAAN FKG	GY-21	F	2001-07-21	JL. HALIMAH 	59	2024-05-29 15:11:22	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP052564-280524-0277	RJJP290524-0481	05-25-64	RAYYEN ALFRIAN JUNEANDRO,TN	KEPANITERAAN FKG	GY-20	M	2002-06-26	JL TITIHAN 6 BLOK HF 13 NO 14	59	2024-05-29 14:47:25	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP075731-290524-0352	RJJP290524-0480	07-57-31	CECELIA SANDRA BAYANUDIN, NY	KEPANITERAAN FKG	GY-19	F	2001-04-23	NAGARAKASIH	59	2024-05-29 14:46:03	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP075644-290524-0351	RJJP290524-0479	07-56-44	ANDI ADJANI SALWA PUTRI, NN	KEPANITERAAN FKG	GY-18	F	2003-08-11	PERUM SEPINGGAN PRATAMA BLOK E1 NO. 5	59	2024-05-29 14:45:04	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP076902-290524-0347	RJJP290524-0475	07-69-02	PUTRI AYU NURHADIZAH, NN	KEPANITERAAN FKG	GY-17	F	2002-10-04	BALIMATRAMAN NO. 6	59	2024-05-29 14:44:00	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP080917-290524-0066	RJJP290524-0308	08-09-17	AYEESHA FITRYA ADORA, AN	KEPANITERAAN FKG	VI-14	F	2019-06-06	JL. HARAPAN MULIA VI NO. 18	58	2024-05-29 10:20:34	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP079795-290524-0287	RJJP290524-0281	07-97-95	VARISHA HUWAIDA RAMADHINA, AN	KEPANITERAAN FKG	VI-13	F	2018-06-05	JL. HARAPAN MULIA VI NO. 18	58	2024-05-29 10:03:57	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	0	\N
OP057971-300524-0254	RJJP300524-0398	05-79-71	JESSICA PUTRI SOUISA, NN	KEPANITERAAN FKG	GY-29	F	2002-03-08	JLN RADEN FATAH NO 03 RT : 016/003	59	2024-05-30 12:04:25	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP075572-300524-0047	RJJP300524-0387	07-55-72	ATIKA RAHMA MINABARI, NY	KEPANITERAAN FKG	GY-28	F	2000-12-18	JL CENDRAWASIH NO. 99	59	2024-05-30 11:34:35	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP075731-300524-0216	RJJP300524-0360	07-57-31	CECELIA SANDRA BAYANUDIN, NY	KEPANITERAAN FKG	GY-27	F	2001-04-23	NAGARAKASIH	59	2024-05-30 10:33:40	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP075854-300524-0215	RJJP300524-0357	07-58-54	ADILA HIKMAYANTI, NN	KEPANITERAAN FKG	GY-26	F	2002-06-23	KP PUTAT	59	2024-05-30 10:31:17	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	4	\N
OP075860-300524-0212	RJJP300524-0354	07-58-60	IVAN HASAN, TN	KEPANITERAAN FKG	GY-25	M	2000-02-24	JL H SUAIB	59	2024-05-30 10:24:44	Poli Gigi Spesialis Periodonti	3838	drg. Yulia Rachma wijayanti, Sp.Perio,MM	PERUSAHAAN	0	\N
OP081017-300524-0045	RJJP300524-0350	08-10-17	FINA NAILATUL IZZAH SANI, AN	KEPANITERAAN FKG	VI-11	F	2019-02-15	CEMPAKA PUTIH BARAT III NO. 22	58	2024-05-30 10:18:28	Poli Gigi Spesialis Pedodonti	3885	drg. Indira Chairulina Dara, Sp.KGA	PERUSAHAAN	4	\N
OP081008-300524-0248	RJJP300524-0266	08-10-08	BREANIZA DHARI, NY	KEPANITERAAN FKG	SQ-25	F	2001-05-07	KOMP KODAM JAYA BLOK I NO 1	137	2024-05-30 09:16:18	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	4	\N
-	RKG300524-9652	-	Video oklusal	KEPANITERAAN FKG	-	M	2024-05-30	Cempaka putih	10	2024-05-30 21:17:40	Poli Gigi Spesialis Radiologi	3892	drg. Resky Mustafa,M. Kes.,Sp.RKG	PERUSAHAAN	0	\N
OP057971-310524-0203	RJJP310524-0314	05-79-71	JESSICA PUTRI SOUISA, NN	KEPANITERAAN FKG	SQ-31	F	2002-03-08	JLN RADEN FATAH NO 03 RT : 016/003	137	2024-05-31 09:28:21	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	0	\N
OP073236-310524-0081	RJJP310524-0271	07-32-36	NADZWA RETHA YUSNITA, NN	KEPANITERAAN FKG	DU-37	F	2005-03-03	JL CEMPAKA INDAH NO 13	137	2024-05-31 09:06:32	Poli Gigi Spesialis Konservasi/Endodonsi	3886	drg. Dudik Winarko, Sp.KG	PERUSAHAAN	0	\N
OP081078-310524-0029	RJJP310524-0206	08-10-78	NAZIFA AULIA SHAHLA, NN	KEPANITERAAN FKG	SQ-30	F	2006-07-14	JL. PADEMANGAN IV GG XI	137	2024-05-31 08:28:21	Poli Gigi Spesialis Konservasi/Endodonsi	3836	drg. Chaira Musytaka Sukma, Sp.KG	PERUSAHAAN	0	\N
-	RKG310524-7044	-	Video Periapikal	KEPANITERAAN FKG	-	F	2024-05-31	Cempaka putih	10	2024-05-31 10:50:48	Poli Gigi Spesialis Radiologi	3887	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	PERUSAHAAN	0	\N
\.


--
-- TOC entry 3735 (class 0 OID 16564)
-- Dependencies: 243
-- Data for Name: personal_access_tokens; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.personal_access_tokens (id, tokenable_type, tokenable_id, name, token, abilities, last_used_at, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3737 (class 0 OID 16570)
-- Dependencies: 245
-- Data for Name: semesters; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.semesters (id, semestername, semestervalue, active, created_at, updated_at) FROM stdin;
c5ee4d99-e52c-4c98-9548-7cb94969607a	Semester 1	1	1	\N	2024-02-21 20:24:28
a60d9ffd-931e-4274-96ed-0967514c55c3	Semester 2	2	1	\N	2024-02-21 20:24:51
59f8c4f8-4f03-41fc-a259-110508f5ee02	Semester 3	3	1	\N	2024-02-22 13:24:25
e61eee2c-3baf-4a08-828f-29f761594a40	Semester 4	4	1	\N	\N
fc711d54-c308-4792-882c-8fef761f4594	Semester 5	5	1	\N	\N
00b88b88-aec2-43b4-aca5-d33fcec7ce46	Semester 6	6	1	\N	\N
4cc45c1e-0fdf-42c8-be81-2eeb049842ff	Semester 7	7	1	\N	\N
034ea7cf-00c2-48b7-aff7-0831f55dd334	Semester 8	8	1	\N	\N
\.


--
-- TOC entry 3738 (class 0 OID 16573)
-- Dependencies: 246
-- Data for Name: specialistgroups; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.specialistgroups (id, name, active, created_at, updated_at) FROM stdin;
95114031-c490-49d9-b76b-9edf50dacc23	GIGI	1	\N	\N
\.


--
-- TOC entry 3739 (class 0 OID 16576)
-- Dependencies: 247
-- Data for Name: specialists; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.specialists (id, specialistname, groupspecialistid, active, created_at, updated_at, simrsid) FROM stdin;
4b5ca39c-5a37-46d1-8198-3fe2202775a2	Orthodonty	95114031-c490-49d9-b76b-9edf50dacc23	1	\N	\N	46
5756d1b9-34b4-4d49-b5fb-76b68bbd736e	Pedodonti	95114031-c490-49d9-b76b-9edf50dacc23	1	\N	\N	58
88e2a725-abb3-459d-99dc-69a43a39d504	Periodonti	95114031-c490-49d9-b76b-9edf50dacc23	1	\N	\N	59
a89710d5-0c4c-4823-9932-18ce001d71a5	Prostodonti	95114031-c490-49d9-b76b-9edf50dacc23	1	\N	\N	60
add71909-11e5-4adb-ab6e-919444d4aab7	Konservasi	95114031-c490-49d9-b76b-9edf50dacc23	1	\N	\N	137
cf504bf3-803c-432c-afe1-d718824359d5	Radiologi Kedokteran Gigi	95114031-c490-49d9-b76b-9edf50dacc23	1	\N	2024-03-04 14:43:00	10
\.


--
-- TOC entry 3740 (class 0 OID 16579)
-- Dependencies: 248
-- Data for Name: students; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.students (id, name, nim, semesterid, specialistid, datein, university, hospitalfrom, hospitalto, active, created_at, updated_at) FROM stdin;
3b358ee0-c278-4cee-8c99-55d87d2bc142	Mutia Permata Putri	4122023039	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-02-19	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	\N
54be3d06-dec5-4ec0-82d9-fd11ee818217	Amalia Rafa Wulandari	4122023025	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-02-19	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	\N
515b8bca-8641-497e-8cea-652286f98d56	Jihan Ar Rohim	4122023035	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-02-19	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	\N
a9c3e3af-a31e-4ab0-be8d-f7035c065805	Qanita Regina Maharani	4122023041	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-02-19	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	\N
651a9671-98ec-4b20-b125-c0e396839a55	Adila Hikmayanti	4122023024	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-02-19	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	\N
e3e7432f-6de7-45fd-b779-710c48a16575	Rayyen Alfian Juneanro	4122023042	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-02-19	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	\N
f95f6c6c-aeed-44d0-acd6-53e900611129	Sahri Muhamad Risky	4122023043	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-02-19	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	\N
6bb189f0-19aa-43b0-bc03-5f0d620bbb64	Andi Adjani Salwa Putri	4122023026	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-03-07	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	\N
d4c0c8de-eb22-41ec-b397-ccb541407b9a	Atika Rahma Minabari	4122023027	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-03-07	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	\N
eadbbcdf-4dca-4aaa-aab3-fede3019d756	Farah Alifah Rahayu	4122023031	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-03-07	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	\N
847d4b7b-d2d4-4711-a3c8-793b8e046886	Ivo Resky Primigo	4122023033	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-03-07	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	\N
daec3c5f-b8e9-4746-bedb-0b00324c2304	Karina Ivana Nariswari	4122023036	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-03-07	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	\N
41661e2e-0c83-4282-b67e-8c68037fa498	Khairunnisa Nabiilah Putri	4122023037	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-03-07	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	\N
db9f2b64-30fb-415e-bff5-e02d870862b1	Laras Fajri Nanda Widiiswa	4122023038	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-03-07	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	\N
9b609659-0c7e-492c-a49f-04a3ceeccbb0	Putri Ayu Nurhadizah	4122023040	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-03-07	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	\N
97ae28a1-f02b-4b68-9459-599d87845fc7	Sekar Decita Ananda Iswanti	4122023044	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-03-07	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	\N
c6df72a6-1070-48d7-9342-ec799bf9f5b1	Faika Zahra Chairunnisa	4122023030	c5ee4d99-e52c-4c98-9548-7cb94969607a	88e2a725-abb3-459d-99dc-69a43a39d504	2024-03-07	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	2024-04-02 15:33:17
12a16ac8-2655-4f67-b69f-3615d5054a13	Jessica Putri Souisa	4122023034	034ea7cf-00c2-48b7-aff7-0831f55dd334	add71909-11e5-4adb-ab6e-919444d4aab7	2024-02-19	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	2024-04-03 12:04:41
29b9777c-1cc5-4839-82b3-935db28cb9a8	Ivan Hasan	4122023032	034ea7cf-00c2-48b7-aff7-0831f55dd334	5756d1b9-34b4-4d49-b5fb-76b68bbd736e	2024-02-19	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	2024-04-03 12:08:37
29cfee77-5f9a-4ab5-934d-f4973664092b	Cecelia Sandra Bayanudin	4122023029	034ea7cf-00c2-48b7-aff7-0831f55dd334	cf504bf3-803c-432c-afe1-d718824359d5	2024-03-07	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	2024-04-03 15:00:12
254fbe52-438a-4e69-963c-1103a4482b51	Shabrina Ghisani M	4122023045	034ea7cf-00c2-48b7-aff7-0831f55dd334	cf504bf3-803c-432c-afe1-d718824359d5	2024-02-19	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	2024-04-08 08:02:28
b395141d-d975-49e3-94b8-88447d2d0245	Breaniza Dhari	4122023028	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-03-07	4dedaec1-4e5f-4492-9226-1e9af6aaf34b	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	f0b4b4d1-d41e-4b65-a85a-4af1f9cd5abc	1	\N	2024-05-14 09:40:20
\.


--
-- TOC entry 3741 (class 0 OID 16582)
-- Dependencies: 249
-- Data for Name: trsassesments; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.trsassesments (id, assesmentgroupid, studentid, lectureid, yearid, semesterid, specialistid, transactiondate, grandotal, assesmenttype, active, created_at, updated_at, idspecialistsimrs, totalbobot, assesmentfinalvalue, lock, datelock, usernamelock, countvisits) FROM stdin;
b1531798-df7e-4a05-a138-8bd7ab168769	1834e4f8-5cdf-4d95-b956-6432c52c61ff	c6df72a6-1070-48d7-9342-ec799bf9f5b1	7d02dd7e-3828-4576-9974-95e01c8af40b	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	88e2a725-abb3-459d-99dc-69a43a39d504	2024-04-02 00:00:00	0	5	1	\N	2024-04-02 15:40:27	59	100	\N	0	\N	\N	\N
38d82967-0c0f-46f1-8371-4b4c1c2b9e09	36da7989-cedc-49c4-82e1-aabead99a6c2	c6df72a6-1070-48d7-9342-ec799bf9f5b1	7d02dd7e-3828-4576-9974-95e01c8af40b	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	88e2a725-abb3-459d-99dc-69a43a39d504	2024-04-02 00:00:00	284.6	5	1	\N	2024-04-02 15:47:54	59	40	42.69	1	2024-04-02 15:47:54	drg. Yulia Rachma wijayanti, Sp.Perio,MM	\N
3113f740-1ad3-4d5a-8961-6698d0c62e1a	06ce9f8a-dc32-4798-99f8-512104e411a0	254fbe52-438a-4e69-963c-1103a4482b51	9971c081-ebd7-4980-a5df-af1208046f26	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-04-02 00:00:00	0	1	1	\N	2024-04-02 21:32:50	46	40	\N	0	\N	\N	\N
f92da2e3-1d4b-4205-8ea5-d00d70d07c82	3b025e64-cedc-4ac2-b2ec-8f44ba46e89a	254fbe52-438a-4e69-963c-1103a4482b51	9971c081-ebd7-4980-a5df-af1208046f26	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-04-02 00:00:00	80	1	1	\N	2024-04-02 21:14:31	46	40	9.6	0	\N	\N	\N
07486210-f794-43b2-bac8-25e3d9e69141	60ddaea5-aec0-4965-9c76-00f0080a5790	254fbe52-438a-4e69-963c-1103a4482b51	9971c081-ebd7-4980-a5df-af1208046f26	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-04-02 00:00:00	22	1	1	\N	2024-04-02 21:36:18	46	40	3.3	1	2024-04-02 21:11:14	drg. Vika Novia Zamri, Sp.Ort	\N
49f95ca3-7345-44d7-adbb-bebf53ddcdec	2feb22f2-f122-4cf2-9ada-6238d4369a18	254fbe52-438a-4e69-963c-1103a4482b51	9971c081-ebd7-4980-a5df-af1208046f26	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-04-02 00:00:00	80	1	1	\N	2024-04-02 21:20:06	46	40	6.4	0	\N	\N	\N
97ff094b-4e1b-4b0c-ae62-bf142c0753c6	a7a33913-a538-4c67-b755-5ee038e5c2d0	29b9777c-1cc5-4839-82b3-935db28cb9a8	414ca7b8-a85d-4c36-b094-de815fccbef0	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	5756d1b9-34b4-4d49-b5fb-76b68bbd736e	2024-04-03 00:00:00	0	3	1	\N	2024-04-03 12:23:59	58	100	\N	0	\N	\N	\N
6f318b3b-728e-496f-bec6-6b89cc1d0f00	5e362dfd-6121-4041-a98a-f21dd06441de	254fbe52-438a-4e69-963c-1103a4482b51	9971c081-ebd7-4980-a5df-af1208046f26	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-04-02 00:00:00	68	1	1	\N	2024-04-02 21:09:04	46	40	6.12	1	2024-04-02 21:09:04	drg. Vika Novia Zamri, Sp.Ort	\N
16101fec-a747-4b02-9766-8ee4b9fe9e11	22a0e98a-a096-4bef-880b-e94e81429241	254fbe52-438a-4e69-963c-1103a4482b51	9971c081-ebd7-4980-a5df-af1208046f26	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-04-02 00:00:00	62	1	1	\N	2024-04-02 20:58:48	46	40	2.48	1	2024-04-02 20:58:37	drg. Vika Novia Zamri, Sp.Ort	\N
765b403c-8c79-473c-a3d3-2acc337e6b9b	2feb22f2-f122-4cf2-9ada-6238d4369a18	254fbe52-438a-4e69-963c-1103a4482b51	414ca7b8-a85d-4c36-b094-de815fccbef0	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-04-03 00:00:00	0	1	1	\N	2024-04-03 12:24:43	46	40	\N	0	\N	\N	\N
da857f86-1e75-4703-a6e8-b9453625bd6b	2d589f54-d525-4de1-bf7a-92dddda02e4c	254fbe52-438a-4e69-963c-1103a4482b51	9971c081-ebd7-4980-a5df-af1208046f26	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-04-02 00:00:00	72	1	1	\N	2024-04-02 21:18:09	46	40	2.16	0	\N	\N	\N
a2553d01-639d-4bb6-9975-e7842f0537dd	23cb5164-8204-44be-ba28-e39ffe2cdb1f	12a16ac8-2655-4f67-b69f-3615d5054a13	c5281a78-1a04-4ba7-865e-bccc367f4844	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	add71909-11e5-4adb-ab6e-919444d4aab7	2024-04-03 00:00:00	157	4	1	\N	2024-04-03 14:47:41	137	100	11.775	0	\N	\N	\N
00a77507-e7b4-443c-b191-da36a6678174	90ce231f-a7ab-4e48-9b4d-5823e8314175	254fbe52-438a-4e69-963c-1103a4482b51	9971c081-ebd7-4980-a5df-af1208046f26	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-04-02 00:00:00	56	1	1	\N	2024-04-02 21:02:35	46	40	4.48	1	2024-04-02 21:02:35	drg. Vika Novia Zamri, Sp.Ort	\N
9a98f4d3-aeb7-400f-bec3-66fbe3ccac8f	c844e587-0cff-487a-a81f-b5406215a1e8	12a16ac8-2655-4f67-b69f-3615d5054a13	c5281a78-1a04-4ba7-865e-bccc367f4844	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	add71909-11e5-4adb-ab6e-919444d4aab7	2024-04-03 00:00:00	216	4	1	\N	2024-04-03 14:37:11	137	100	21.6	0	\N	\N	\N
b65819bc-65b0-44fc-895d-9bf575416246	352f12bb-e8b9-4986-83cd-bfc882379632	254fbe52-438a-4e69-963c-1103a4482b51	9971c081-ebd7-4980-a5df-af1208046f26	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-04-02 00:00:00	73	1	1	\N	2024-04-02 21:22:30	46	40	5.11	0	\N	\N	\N
cbc76149-33b7-4b54-a4ef-ca0576195864	832939f0-0ace-4fd3-89aa-e659550f041e	254fbe52-438a-4e69-963c-1103a4482b51	9971c081-ebd7-4980-a5df-af1208046f26	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-04-02 00:00:00	0	6	1	\N	\N	46	0	\N	0	\N	\N	\N
3b552933-8c5a-48ef-96e5-26fcc800697e	c1ff27fa-7779-4167-ba79-b55253758f95	254fbe52-438a-4e69-963c-1103a4482b51	9971c081-ebd7-4980-a5df-af1208046f26	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-04-02 00:00:00	84	1	1	\N	2024-04-02 21:21:17	46	40	4.2	0	\N	\N	\N
6b41c5e8-c113-46bc-bbc6-e580b286c88a	ead3749e-9673-442a-b817-221df6d8e3c6	12a16ac8-2655-4f67-b69f-3615d5054a13	c5281a78-1a04-4ba7-865e-bccc367f4844	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	add71909-11e5-4adb-ab6e-919444d4aab7	2024-04-03 00:00:00	0	4	1	\N	2024-04-03 14:48:44	137	100	\N	0	\N	\N	\N
5bc1f793-31dc-4f21-a46a-cfab00cec084	a5cb8841-1d03-4102-918f-5a8b7e3456fd	254fbe52-438a-4e69-963c-1103a4482b51	9971c081-ebd7-4980-a5df-af1208046f26	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-04-02 00:00:00	80	1	1	\N	2024-04-02 21:29:02	46	40	4	1	2024-04-02 21:29:02	drg. Vika Novia Zamri, Sp.Ort	\N
7e6b4293-adc6-400c-9101-d45ea91f2b5a	5f1bf278-5507-418a-8def-8d9f0c5709d8	254fbe52-438a-4e69-963c-1103a4482b51	9971c081-ebd7-4980-a5df-af1208046f26	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	4b5ca39c-5a37-46d1-8198-3fe2202775a2	2024-04-02 00:00:00	70	1	1	\N	2024-04-02 21:23:45	46	40	3.5	0	\N	\N	\N
afd29ff9-e6eb-4248-8f66-30af29d620c5	061105f4-25d6-4def-9849-07f2c521f33d	12a16ac8-2655-4f67-b69f-3615d5054a13	c5281a78-1a04-4ba7-865e-bccc367f4844	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	add71909-11e5-4adb-ab6e-919444d4aab7	2024-04-03 00:00:00	190	4	1	\N	2024-04-03 14:42:43	137	100	23.75	0	\N	\N	\N
aa05c4f0-5523-40ec-8ae5-18cd5064a7d6	596b9232-d58b-4f11-83ca-5afe81fce60c	12a16ac8-2655-4f67-b69f-3615d5054a13	c5281a78-1a04-4ba7-865e-bccc367f4844	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	add71909-11e5-4adb-ab6e-919444d4aab7	2024-04-03 00:00:00	208	4	1	\N	2024-04-03 14:43:40	137	100	15.6	0	\N	\N	\N
22ced2b9-64c9-42f9-b898-3d0980836a02	1ec61be0-561e-45d9-ab6e-0af6159afe28	12a16ac8-2655-4f67-b69f-3615d5054a13	c5281a78-1a04-4ba7-865e-bccc367f4844	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	add71909-11e5-4adb-ab6e-919444d4aab7	2024-04-03 00:00:00	0	4	1	\N	2024-04-03 13:18:52	137	100	\N	0	\N	\N	\N
b34da4ce-b23a-449e-ad96-f2b738cbca7c	18ba4183-db88-4de8-af99-6dd83d9b075d	29cfee77-5f9a-4ab5-934d-f4973664092b	2eab15ef-fa97-45ce-a575-cd06a5bbea8d	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	cf504bf3-803c-432c-afe1-d718824359d5	2024-04-04 00:00:00	0	5	1	\N	2024-04-04 09:31:55	46	100	\N	0	\N	\N	\N
c5ed052d-cfed-4151-ab46-43c26ae3601d	c844e587-0cff-487a-a81f-b5406215a1e8	12a16ac8-2655-4f67-b69f-3615d5054a13	c5281a78-1a04-4ba7-865e-bccc367f4844	f70f6fbf-176f-4e19-9396-fec8c50dd62c	c5ee4d99-e52c-4c98-9548-7cb94969607a	add71909-11e5-4adb-ab6e-919444d4aab7	2024-04-03 00:00:00	0	4	1	\N	2024-04-03 14:49:13	137	100	\N	0	\N	\N	\N
b458ab26-728c-49ae-8415-718a07f6ebc9	ead3749e-9673-442a-b817-221df6d8e3c6	12a16ac8-2655-4f67-b69f-3615d5054a13	c5281a78-1a04-4ba7-865e-bccc367f4844	04f1c1a1-625a-4186-ac68-28e1e71c6777	e61eee2c-3baf-4a08-828f-29f761594a40	add71909-11e5-4adb-ab6e-919444d4aab7	2024-04-03 00:00:00	164	4	1	\N	2024-04-03 14:45:25	137	100	20.5	0	\N	\N	\N
6f46dad7-229b-44d4-a6c1-6a22d7034f61	36e976a1-7b53-4d82-a025-72c3de4e1ed9	29cfee77-5f9a-4ab5-934d-f4973664092b	2eab15ef-fa97-45ce-a575-cd06a5bbea8d	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	cf504bf3-803c-432c-afe1-d718824359d5	2024-04-04 00:00:00	80	1	1	\N	2024-04-04 09:25:34	46	80	64	0	\N	\N	\N
7851db96-24fc-4f7f-ab39-8314ffb40e2f	19633f89-3711-4827-9fc9-fdb49316e755	254fbe52-438a-4e69-963c-1103a4482b51	9fdbc56a-a5d2-4e6b-bd83-7b85e4830473	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	a89710d5-0c4c-4823-9932-18ce001d71a5	2024-04-04 00:00:00	0	1	1	\N	2024-04-04 08:33:29	60	0	\N	0	\N	\N	\N
f4d747ef-fae8-460b-a846-a7825a226ba2	700d3334-6b14-4b7a-8973-dc0470f55c51	29cfee77-5f9a-4ab5-934d-f4973664092b	2eab15ef-fa97-45ce-a575-cd06a5bbea8d	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	cf504bf3-803c-432c-afe1-d718824359d5	2024-04-04 00:00:00	80	1	1	\N	2024-04-04 09:46:57	46	80	0	0	\N	\N	\N
1a59f759-fb18-42f9-8a58-da67c4a0e716	36e976a1-7b53-4d82-a025-72c3de4e1ed9	29cfee77-5f9a-4ab5-934d-f4973664092b	2eab15ef-fa97-45ce-a575-cd06a5bbea8d	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	cf504bf3-803c-432c-afe1-d718824359d5	2024-04-04 00:00:00	0	5	1	\N	2024-04-04 09:31:01	46	80	\N	0	\N	\N	\N
c91514be-bbcd-4474-a54e-c5493943aa16	18ba4183-db88-4de8-af99-6dd83d9b075d	29cfee77-5f9a-4ab5-934d-f4973664092b	2eab15ef-fa97-45ce-a575-cd06a5bbea8d	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	cf504bf3-803c-432c-afe1-d718824359d5	2024-04-04 00:00:00	96	1	1	\N	2024-04-04 09:49:03	46	100	0	0	\N	\N	\N
f1235601-d6bc-4844-84a1-1e18988c2dbf	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	29cfee77-5f9a-4ab5-934d-f4973664092b	2eab15ef-fa97-45ce-a575-cd06a5bbea8d	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	cf504bf3-803c-432c-afe1-d718824359d5	2024-04-04 00:00:00	80	1	1	\N	2024-04-04 09:47:46	46	80	0	0	\N	\N	\N
15ea3d80-7ebd-40b8-8c5d-1e534c1ec6c6	2569196c-7dfd-4ab3-9845-0cc1fe7fc1e9	29cfee77-5f9a-4ab5-934d-f4973664092b	2eab15ef-fa97-45ce-a575-cd06a5bbea8d	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	cf504bf3-803c-432c-afe1-d718824359d5	2024-04-04 00:00:00	0	1	1	\N	2024-04-04 09:49:26	46	80	\N	0	\N	\N	\N
8afc6ac5-dfde-453b-bf55-c225c5e8a1d2	79d64714-b496-414a-a28c-5cfd319280e9	29cfee77-5f9a-4ab5-934d-f4973664092b	2eab15ef-fa97-45ce-a575-cd06a5bbea8d	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	cf504bf3-803c-432c-afe1-d718824359d5	2024-04-04 00:00:00	40	1	1	\N	2024-04-04 09:51:58	46	80	32	0	\N	\N	\N
f1d81703-6390-4b29-b9d8-1fbaf6480c1b	608ea017-a9c9-4c54-9870-d82ad90c868e	29cfee77-5f9a-4ab5-934d-f4973664092b	2eab15ef-fa97-45ce-a575-cd06a5bbea8d	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	cf504bf3-803c-432c-afe1-d718824359d5	2024-04-04 00:00:00	100	1	1	\N	2024-04-04 09:52:57	46	100	100	0	\N	\N	\N
271c46df-d1e1-440c-a3bd-5a865c088441	8f01380d-cf81-4e20-9fb1-6e416b18ab5a	29cfee77-5f9a-4ab5-934d-f4973664092b	2eab15ef-fa97-45ce-a575-cd06a5bbea8d	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	cf504bf3-803c-432c-afe1-d718824359d5	2024-04-04 00:00:00	80	1	1	\N	2024-04-04 09:53:34	46	80	0	1	2024-04-04 09:53:34	drg. Anugrah Prayudi Raharjo	\N
cb433dc6-3620-4f49-9e68-cda03ebfd085	19633f89-3711-4827-9fc9-fdb49316e755	254fbe52-438a-4e69-963c-1103a4482b51	2eab15ef-fa97-45ce-a575-cd06a5bbea8d	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	a89710d5-0c4c-4823-9932-18ce001d71a5	2024-04-04 00:00:00	0	1	1	\N	2024-04-04 10:31:44	60	0	\N	0	\N	\N	\N
ec60fd17-2a42-44d0-a740-886527e68336	4f078342-5e30-4774-abec-97a9d1c5abe9	29b9777c-1cc5-4839-82b3-935db28cb9a8	414ca7b8-a85d-4c36-b094-de815fccbef0	04f1c1a1-625a-4186-ac68-28e1e71c6777	034ea7cf-00c2-48b7-aff7-0831f55dd334	5756d1b9-34b4-4d49-b5fb-76b68bbd736e	2024-04-05 00:00:00	0	3	1	\N	2024-04-05 09:59:25	58	100	0	0	\N	\N	\N
9926c557-6ee3-4e8b-8bdf-e8d960a137bf	4c58ddcf-c320-4bc3-b43a-e899997e48f6	29b9777c-1cc5-4839-82b3-935db28cb9a8	a8a87927-17f3-44fc-9867-0acf2cf0881a	04f1c1a1-625a-4186-ac68-28e1e71c6777	a60d9ffd-931e-4274-96ed-0967514c55c3	5756d1b9-34b4-4d49-b5fb-76b68bbd736e	2024-04-07 00:00:00	0	3	1	\N	2024-04-08 05:51:50	58	100	\N	0	\N	\N	\N
27f5b271-b7f7-4681-b30b-c287484294cc	a7a33913-a538-4c67-b755-5ee038e5c2d0	29b9777c-1cc5-4839-82b3-935db28cb9a8	a8a87927-17f3-44fc-9867-0acf2cf0881a	04f1c1a1-625a-4186-ac68-28e1e71c6777	a60d9ffd-931e-4274-96ed-0967514c55c3	5756d1b9-34b4-4d49-b5fb-76b68bbd736e	2024-04-08 00:00:00	0	3	1	\N	2024-04-08 08:28:50	58	100	\N	0	\N	\N	\N
ff6f38fe-01b4-4509-b348-f82af0320322	c844e587-0cff-487a-a81f-b5406215a1e8	12a16ac8-2655-4f67-b69f-3615d5054a13	a8a87927-17f3-44fc-9867-0acf2cf0881a	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	add71909-11e5-4adb-ab6e-919444d4aab7	2024-04-20 00:00:00	0	4	1	\N	2024-04-20 20:17:07	137	100	\N	1	2024-04-20 20:16:51	drg. Ufo Pramigi	\N
795c02a4-5504-48ef-bc59-80b4488ac114	ead3749e-9673-442a-b817-221df6d8e3c6	12a16ac8-2655-4f67-b69f-3615d5054a13	a8a87927-17f3-44fc-9867-0acf2cf0881a	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	add71909-11e5-4adb-ab6e-919444d4aab7	2024-04-20 00:00:00	16	4	1	\N	2024-04-20 20:22:05	137	100	2	1	2024-04-20 20:22:05	drg. Ufo Pramigi	\N
14e4098d-2a3e-4245-8353-bd4ed351e6a6	36e976a1-7b53-4d82-a025-72c3de4e1ed9	a9c3e3af-a31e-4ab0-be8d-f7035c065805	a8a87927-17f3-44fc-9867-0acf2cf0881a	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	cf504bf3-803c-432c-afe1-d718824359d5	2024-04-23 00:00:00	99	1	1	\N	2024-04-23 20:48:13	10	80	4.95	1	2024-04-23 20:48:13	drg. Ufo Pramigi	\N
aa81ee4d-ad8f-42f1-ae71-cf3d5e6b8eb4	23cb5164-8204-44be-ba28-e39ffe2cdb1f	12a16ac8-2655-4f67-b69f-3615d5054a13	a8a87927-17f3-44fc-9867-0acf2cf0881a	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	add71909-11e5-4adb-ab6e-919444d4aab7	2024-04-20 00:00:00	6	4	1	\N	2024-04-20 20:24:23	137	100	0.45	1	2024-04-20 20:24:23	drg. Ufo Pramigi	\N
fac9a30d-6639-42bd-b7b8-6efc4756e8b9	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	eadbbcdf-4dca-4aaa-aab3-fede3019d756	2eab15ef-fa97-45ce-a575-cd06a5bbea8d	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	cf504bf3-803c-432c-afe1-d718824359d5	2024-04-23 00:00:00	0	1	1	\N	\N	10	0	\N	0	\N	\N	\N
5e457df6-26e2-4f65-9acf-6cc958eea150	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	eadbbcdf-4dca-4aaa-aab3-fede3019d756	8af4f325-7be0-4bc0-ac07-851d2543c878	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	cf504bf3-803c-432c-afe1-d718824359d5	2024-04-23 00:00:00	0	1	1	\N	\N	10	0	\N	0	\N	\N	\N
4a4ca4bb-6d4b-43b6-a998-46208bb475e7	18ba4183-db88-4de8-af99-6dd83d9b075d	eadbbcdf-4dca-4aaa-aab3-fede3019d756	8af4f325-7be0-4bc0-ac07-851d2543c878	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	cf504bf3-803c-432c-afe1-d718824359d5	2024-04-23 00:00:00	0	1	1	\N	\N	10	0	\N	0	\N	\N	\N
600a436c-314e-409a-ad11-9b7ce5b4eee2	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	eadbbcdf-4dca-4aaa-aab3-fede3019d756	a8a87927-17f3-44fc-9867-0acf2cf0881a	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	cf504bf3-803c-432c-afe1-d718824359d5	2024-04-23 00:00:00	0	1	1	\N	\N	10	0	\N	0	\N	\N	\N
688ed7e4-94c0-4122-8b6a-f6422b7cadc4	36e976a1-7b53-4d82-a025-72c3de4e1ed9	eadbbcdf-4dca-4aaa-aab3-fede3019d756	7d02dd7e-3828-4576-9974-95e01c8af40b	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	cf504bf3-803c-432c-afe1-d718824359d5	2024-04-23 00:00:00	0	1	1	\N	\N	10	0	\N	0	\N	\N	\N
65584d58-1889-4d9b-a5b9-70c940c529d8	2569196c-7dfd-4ab3-9845-0cc1fe7fc1e9	29b9777c-1cc5-4839-82b3-935db28cb9a8	a8a87927-17f3-44fc-9867-0acf2cf0881a	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	cf504bf3-803c-432c-afe1-d718824359d5	2024-05-21 00:00:00	0	1	1	\N	2024-05-21 14:08:28	10	80	\N	0	\N	\N	\N
f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	e3e7432f-6de7-45fd-b779-710c48a16575	b27351d9-1bf2-489a-be00-530575b27cdb	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	cf504bf3-803c-432c-afe1-d718824359d5	2024-05-16 00:00:00	0	1	1	\N	2024-05-22 08:19:02	10	100	\N	0	\N	\N	\N
bff75338-d1a5-4d8f-8e40-cb13f74e0765	97e25278-15f0-4436-9413-548ddb1edac2	e3e7432f-6de7-45fd-b779-710c48a16575	b27351d9-1bf2-489a-be00-530575b27cdb	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	cf504bf3-803c-432c-afe1-d718824359d5	2024-05-16 00:00:00	0	1	1	\N	2024-05-16 11:12:15	10	100	\N	0	\N	\N	\N
7884f9e5-09e0-4b8a-a758-0d0cfcc7a96c	36e976a1-7b53-4d82-a025-72c3de4e1ed9	e3e7432f-6de7-45fd-b779-710c48a16575	b27351d9-1bf2-489a-be00-530575b27cdb	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	cf504bf3-803c-432c-afe1-d718824359d5	2024-05-16 00:00:00	0	1	1	\N	2024-05-21 11:18:26	10	80	\N	1	2024-05-21 11:18:26	drg. Resky Mustafa,M. Kes.,Sp.RKG	\N
8f77d45e-f0ab-4909-90c1-14d37873fe1a	2569196c-7dfd-4ab3-9845-0cc1fe7fc1e9	e3e7432f-6de7-45fd-b779-710c48a16575	b27351d9-1bf2-489a-be00-530575b27cdb	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	cf504bf3-803c-432c-afe1-d718824359d5	2024-05-16 00:00:00	0	1	1	\N	2024-05-16 11:14:44	10	80	\N	0	\N	\N	\N
2c25d4d7-d361-42d1-bfc2-3dc7b3909c70	18ba4183-db88-4de8-af99-6dd83d9b075d	e3e7432f-6de7-45fd-b779-710c48a16575	b27351d9-1bf2-489a-be00-530575b27cdb	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	cf504bf3-803c-432c-afe1-d718824359d5	2024-05-16 00:00:00	0	1	1	\N	2024-05-21 11:35:15	10	100	\N	0	\N	\N	\N
fd4b7500-d73b-419d-acd1-fed1046d6138	16e7fcab-101f-498c-8989-062ec832c8b8	e3e7432f-6de7-45fd-b779-710c48a16575	b27351d9-1bf2-489a-be00-530575b27cdb	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	cf504bf3-803c-432c-afe1-d718824359d5	2024-05-21 00:00:00	0	1	1	\N	2024-05-21 11:37:17	10	80	\N	0	\N	\N	\N
4962d0eb-eb2f-4205-ba63-fceaffdf21be	27dc8ac4-7abf-4a92-9c03-2ae5f60be28e	29b9777c-1cc5-4839-82b3-935db28cb9a8	a8a87927-17f3-44fc-9867-0acf2cf0881a	04f1c1a1-625a-4186-ac68-28e1e71c6777	c5ee4d99-e52c-4c98-9548-7cb94969607a	cf504bf3-803c-432c-afe1-d718824359d5	2024-05-22 00:00:00	0	1	1	\N	2024-05-22 13:18:33	10	100	\N	0	\N	\N	\N
\.


--
-- TOC entry 3743 (class 0 OID 16599)
-- Dependencies: 252
-- Data for Name: type_five_trsdetailassesments; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.type_five_trsdetailassesments (id, trsassesmentid, assesmentdetailid, assesmentdescription, transactiondate, assesmentbobotvalue, assesmentscore, active, created_at, updated_at, assementvalue, kodesub, norm, namapasien, nilaitindakan_awal, nilaisikap_awal, nilaitindakan_akhir, nilaisikap_akhir, assesmentvalue_kondite) FROM stdin;
b616238c-3720-434f-8a99-5cfffb3375f4	38d82967-0c0f-46f1-8371-4b4c1c2b9e09	46c34045-01a8-4f41-9c1f-2f2bbb71d396	Pemeriksaan (pengisian data pasien, keluhan utama, anemnesis, pemeriksaan EO, IO dan radiografis)	\N	1	1	1	\N	2024-04-02 15:44:38	1	0	\N	\N	\N	\N	\N	\N	\N
29352d20-3f17-4c02-955e-3ed6fa888fb5	38d82967-0c0f-46f1-8371-4b4c1c2b9e09	12fc6561-fe2f-48cc-a98f-9e15001a473c	Diagnosis Kerja (nilai 2= sesuai dengan hasil pemeriksaan, nilai< 2= kurang\nsesuai hasil pemeriksaan)	\N	2	4	1	\N	2024-04-02 15:44:43	2	0	\N	\N	\N	\N	\N	\N	\N
fe67edf6-a009-45f9-938b-a95675608bd0	38d82967-0c0f-46f1-8371-4b4c1c2b9e09	4a8119ee-ef0a-4c57-84bf-56ac116fafc9	Rencana Perawatan (nilai 2= sesuai dengan terapi periodontal suportif, nilai < 2= kurang sesuai)	\N	2	2	1	\N	2024-04-02 15:44:52	1	0	\N	\N	\N	\N	\N	\N	\N
199b0ed3-9fd1-4d47-9d84-c9e57cf32e6d	38d82967-0c0f-46f1-8371-4b4c1c2b9e09	77a9fe42-410a-4e42-b6aa-73be5549933a	Kunjungan III (Kontrol II)	\N	0	74	1	\N	2024-04-02 15:47:44	0	0	\N	\N	74	74	59.2	14.8	\N
9c24c82e-2a8b-4b14-86f6-0ad78d2d7374	38d82967-0c0f-46f1-8371-4b4c1c2b9e09	5cd76271-7139-48f0-9f57-8796250190bf	Prognosis (nilai 2= sesuai dengan hasil pemeriksaan, nilai < 2= kurang sesuai)	\N	1	1	1	\N	2024-04-02 15:44:59	1	0	\N	\N	\N	\N	\N	\N	\N
f9a4ad5f-430c-4e75-9bb6-fbba794d02bc	38d82967-0c0f-46f1-8371-4b4c1c2b9e09	f4d45031-0e77-4dab-854e-4e1687a933d5	Penyelesaian (data rekam medik dan diskusi diselesaikan di hari yang sama (nilai 2), 2 hari setelah kerja (nilai 1), > 2 hari kerja (nilai < 1))	\N	1	1	1	\N	2024-04-02 15:45:06	1	0	\N	\N	\N	\N	\N	\N	\N
ad3fa3b5-8ab9-49f8-b7f7-67ada40f344c	38d82967-0c0f-46f1-8371-4b4c1c2b9e09	a6268a58-1a7b-482e-9f51-0a84cfe9f8d9	Persiapan awal: kriteria pasien poket ≤ 3 mm, kalkulus kelas 1 (supragingiva) atau kalkulus kelas 2 (subgingiva); pasien bersedia dirawat, menandatangani informed consent	\N	1	1	1	\N	2024-04-02 15:45:11	1	0	\N	\N	\N	\N	\N	\N	\N
5b356136-d211-4094-ba71-2669905d9194	38d82967-0c0f-46f1-8371-4b4c1c2b9e09	dbd944c7-1a89-4b51-8957-58cc77004e61	Skor terisi lengkap dan benar: Indeks plak, Indeks kalkulus, bleeding on probing (BOP), menginstruksikan pasien kumur antiseptik	\N	2	2	1	\N	2024-04-02 15:45:17	1	0	\N	\N	\N	\N	\N	\N	\N
d6133f9c-5c68-417a-9c94-9f33e1057d4a	38d82967-0c0f-46f1-8371-4b4c1c2b9e09	4e55c610-f1ad-4d1b-8cb0-1c06e83c8786	Alat: kaca mulut, sonde halfmoon, pinset, probe periodontal, skaler manual (Sickle, Hoe, Chisel), brush/rubber cup. Bahan: pasta profilkasis, pumis, hidrogen peroksida (H2O2 3 %)/povidone iodin 1%, aquabidest, tampon, cotton roll, cotton pellet, siring irigasi.	\N	1	1	1	\N	2024-04-02 15:45:23	1	0	\N	\N	\N	\N	\N	\N	\N
bc17b2dc-c6b4-41ac-b1a5-229d4df5caff	38d82967-0c0f-46f1-8371-4b4c1c2b9e09	1aec6f4f-382a-4e11-b52a-64536ab6c70f	Posisi kerja operator ergonomis. Pencahayaan, arah pandang, retraksi lidah- mukosa-bibir sesuai daerah kerja	\N	6	6	1	\N	2024-04-02 15:45:28	1	0	\N	\N	\N	\N	\N	\N	\N
5804dcf0-f579-4965-94cb-b5d07308aee2	38d82967-0c0f-46f1-8371-4b4c1c2b9e09	d8ca132b-cedc-43c8-96d8-f96520f23c8a	Penggunaan skeler: stabilisasi instrumen (tumpuan dan sandaran jari sesuai regio), adaptasi, angulasi (450), tekanan lateral, arah gerakan (horizontal, oblique dan vertikal) pada sisi kerja, berkontak dengan gigi	\N	9	9	1	\N	2024-04-02 15:45:32	1	0	\N	\N	\N	\N	\N	\N	\N
5aca6119-ed33-4aef-bce9-2228a6a383cb	38d82967-0c0f-46f1-8371-4b4c1c2b9e09	12c9e67f-0125-478a-8dc8-0010f1c4ed62	Kontrol perdarahan: Irigasi H2O2 3% (BOP > 2), kemudian irigasi dengan aquabidest. Aplikasi pasta profilaksis/pumis, aplikasi pada gigi dengan brush/rubber cup (BOP < 2)	\N	8	16	1	\N	2024-04-02 15:46:36	2	0	\N	\N	\N	\N	\N	\N	\N
d27bf42e-8c86-4160-a1c1-3e3756f2177f	38d82967-0c0f-46f1-8371-4b4c1c2b9e09	ac293356-dfad-487a-ad0a-66e06341efd3	Evaluasi: setelah dilakukan scaling, tidak ditemukan kalkulus, stain dan plak baik supragingiva dan subgingiva	\N	3	6	1	\N	2024-04-02 15:46:40	2	0	\N	\N	\N	\N	\N	\N	\N
dadc80f0-003c-4c11-811a-6fd9de300f8c	38d82967-0c0f-46f1-8371-4b4c1c2b9e09	fbcec4fc-0f0c-4b2d-86dc-ba358c885baa	Instruksi pasien: kontrol 7 hari kemudian, pemeliharaan kesehatan gigi dan mulut di rumah	\N	3	6	1	\N	2024-04-02 15:46:44	2	0	\N	\N	\N	\N	\N	\N	\N
fa63fbb7-1bf4-48a7-a1aa-7562dce04780	38d82967-0c0f-46f1-8371-4b4c1c2b9e09	edbb3b8c-26ba-4d4b-b47c-da0a2b640f60	Kunjungan I (Saat skeling)	\N	0	79	1	\N	2024-04-02 15:47:20	0	0	\N	\N	80	75	64	15	\N
469ea738-f856-4d07-84ea-2f8d0d60592d	38d82967-0c0f-46f1-8371-4b4c1c2b9e09	67027213-6a16-4434-88d3-852240568417	Kunjungan II (Kontrol I)	\N	0	75.6	1	\N	2024-04-02 15:47:33	0	0	\N	\N	75	78	60	15.6	\N
ebb9e36e-a127-4e40-9cb6-12c3a1062607	1a59f759-fb18-42f9-8a58-da67c4a0e716	519f2d87-ede2-47fa-98f2-defab532bff3	PEKERJAAN KLINIK	\N	0	0	1	\N	\N	0	1	\N	\N	\N	\N	\N	\N	\N
178aa86f-a0f8-4124-8bf0-03953e084df4	1a59f759-fb18-42f9-8a58-da67c4a0e716	e4179566-439c-4d6e-b7a2-d1a32228978e	Informed Consent	\N	5	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
901f9e36-4d34-472a-9c4f-48cf3240c450	1a59f759-fb18-42f9-8a58-da67c4a0e716	89382123-38f6-4e90-9526-30c7973bf572	Proteksi Radiasi	\N	5	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
8bebba87-9b8d-4956-8b00-36ff06306f6f	1a59f759-fb18-42f9-8a58-da67c4a0e716	77ebd490-e367-4058-be7f-09eac021c473	Posisi Pasien	\N	5	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
7c3892c1-7f3a-41f3-847e-72065c1c2af3	1a59f759-fb18-42f9-8a58-da67c4a0e716	ff6078d5-3b54-4bbd-a00d-cc66d3d1e259	Posisi Film	\N	5	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
b4787b43-743f-454b-890a-8e4b40e650c5	1a59f759-fb18-42f9-8a58-da67c4a0e716	b5280e46-b162-4b9e-bfd0-2f7ab634e077	Posisi Tabung Xray	\N	5	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
055dc49b-deec-4889-8deb-0e181da00c60	1a59f759-fb18-42f9-8a58-da67c4a0e716	650d44b1-6c10-4a94-abf0-21702d538d39	Instruksi Pasien	\N	10	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
4d590e12-e5ca-4633-b664-d6d6cda64286	1a59f759-fb18-42f9-8a58-da67c4a0e716	31d76d93-460c-4c22-8dc9-8ddac3055bd5	Exposure	\N	10	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
4a21f9e8-ac33-47ac-8c33-f4fed379c610	1a59f759-fb18-42f9-8a58-da67c4a0e716	7644b9f2-1729-40eb-a6c5-abe2545a4555	SIKAP	\N	0	0	1	\N	\N	0	2	\N	\N	\N	\N	\N	\N	\N
1a5f005f-fd0c-46ea-8fff-908e54cebb3b	1a59f759-fb18-42f9-8a58-da67c4a0e716	d3bbda49-4696-419d-a770-9e3e9e1bf01d	Inisiatif	\N	0	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
a5990bbc-4bfb-4fbf-b945-3cc1d3179dc2	1a59f759-fb18-42f9-8a58-da67c4a0e716	80a50b4b-28b6-4c24-b1dd-38d04e446437	Disiplin	\N	0	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
bad595ee-48a5-40b2-8ceb-abbcd96479fb	1a59f759-fb18-42f9-8a58-da67c4a0e716	823d56f5-8d50-4ce0-98e1-a6c3eedc143a	Kejujuran	\N	0	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
d0eccb9b-5acd-456a-a8bc-85e1ff28c4ed	1a59f759-fb18-42f9-8a58-da67c4a0e716	9e32d68a-0eb2-48c1-bc52-4a39d4f0d018	Tanggung Jawab	\N	0	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
dcecfff8-31f4-4996-85d5-80da3761100e	1a59f759-fb18-42f9-8a58-da67c4a0e716	ed11558f-8782-44bc-86df-68eced45d5e7	Kerjasama	\N	0	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
73dcbd16-a165-4704-896d-42211abaae17	1a59f759-fb18-42f9-8a58-da67c4a0e716	95e9b0c0-f682-470b-95fe-69472cd7a1a9	Santun terhadap pasien	\N	0	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
5c9eff4e-d11c-4dcf-ac3f-d4e81e710eb6	1a59f759-fb18-42f9-8a58-da67c4a0e716	828a05e8-09ca-404e-ad19-37ea6cf19295	Santun terhadap dosen	\N	0	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
3e06ab95-8548-40c1-b24c-eb10e865d9c4	b34da4ce-b23a-449e-ad96-f2b738cbca7c	89d5f270-9bf7-43ce-a136-ea66e9cf168e	PEKERJAAN KLINIK	\N	0	0	1	\N	\N	0	1	\N	\N	\N	\N	\N	\N	\N
1cacf947-3a56-4e8e-bbb0-7565ee0feb34	b34da4ce-b23a-449e-ad96-f2b738cbca7c	b1bde434-acb3-4d0e-b5ea-f22e0b0940ef	Menerima dan membaca rujukan pemeriksaan  radiograf periapikal, melakukan informed consent pada pasien dan  menulis  pada  buku  catatan  di  ruang Xray	\N	2	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
7485f4ac-169c-4ea3-89a8-aa2c0d98d99a	b34da4ce-b23a-449e-ad96-f2b738cbca7c	e9fe4b01-3356-4836-9b40-b6e2c1f4e246	Mempersiapkan alat xray intraoral, memilih lama eksposur pada panel kontrol dan film yang akan digunakan	\N	2	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
ecadd637-817f-4085-b995-6efceacc8fc6	b34da4ce-b23a-449e-ad96-f2b738cbca7c	8db2983a-640f-4476-bf2f-82fbecefe22a	Mempersilahkan  pasien  untuk  masuk  dan\nmenjelaskan kepada pasien prosedur pemeriksaan radiologis menggunakan teknik periapikal bisektris	\N	5	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
549753de-3fde-422a-b819-725447640f42	b34da4ce-b23a-449e-ad96-f2b738cbca7c	f7f56eee-c3b2-4196-88fe-0b6ee19d17f4	Menggunakan Masker dan Sarung tangan	\N	2	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
365e830b-d674-468e-8474-a1f67c4bc1c0	b34da4ce-b23a-449e-ad96-f2b738cbca7c	3be73c17-b7d0-40b8-a16f-a64591c5a9e5	Pasien diinstruksikan untuk memakai apron pelindung radiasi	\N	3	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
4e065022-33a3-4baf-8bd0-49b568263e4c	b34da4ce-b23a-449e-ad96-f2b738cbca7c	457aae28-a96e-4450-a471-10ff880dccc5	Mempersilahkan pasien duduk di alat xray\ndan memposisikan kepala pasien: \na. Kepala bersandar pada headrest \nb. Bidang sagital tegak lurus lantai\nc. Bidang oklusal sejajar dengan lantai	\N	10	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
a8de1960-51a5-4518-b9cb-54c0082c0b71	b34da4ce-b23a-449e-ad96-f2b738cbca7c	40aa31de-c592-40b9-a2f0-99b45f6d0b94	Meletakkan film   intraoral kedalam mulut pasien, posisi objek yang akan diperiksa berada di  tengah film. Dot  film  berada  di insisal/oklusal gigi.	\N	5	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
548fc54b-7065-46c1-a39c-5448fc10a4ab	b34da4ce-b23a-449e-ad96-f2b738cbca7c	5fdf51ed-449d-4e5f-a62f-4f9ed89e7c26	Jari pasien diarahkan untuk me-fiksasi film	\N	2	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
ffb6b909-275b-4257-9de1-68f4fc91d603	b34da4ce-b23a-449e-ad96-f2b738cbca7c	26fb5ed1-f586-4805-b431-c73e532b850e	Mengatur Tabung eksposi pada:\na. Sudut vertikal disesuaikan objek yang akan diperiksa\nb. Sudut Horizontal disesuaikan objek yang akan diperiksa	\N	10	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
258c4113-b613-4c23-970a-2bf7eb1e9ade	b34da4ce-b23a-449e-ad96-f2b738cbca7c	ab29848c-1713-44d0-8ae6-8ff7a15a7d5d	Mengarahkan tabung eksposi sesuai dengan titik penetrasi objek.	\N	5	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
5e0ce7d7-8f88-4371-ac72-914f95518686	b34da4ce-b23a-449e-ad96-f2b738cbca7c	43f89f49-b5ff-47c6-8b41-f6532256ad31	Menginstruksikan pasien untuk tidak bergerak   dan   dan   menjelaskan   operator akan melakukan eksposi	\N	1	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
c8172454-434d-45f6-b373-92dc7df24df2	b34da4ce-b23a-449e-ad96-f2b738cbca7c	cffbd13b-a92e-46f6-a65a-208136261a11	Memencet tombol eksposi	\N	1	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
4f7cfd8e-bbb2-4cdb-8c70-375abfeb1842	b34da4ce-b23a-449e-ad96-f2b738cbca7c	8f9a5f01-1723-4f02-952a-45ffffd2b050	Mengeluarkan  fim  dari  mulut  pasien  dan mempersilahkan   pasien   berdiri,   melepas apron pelindung radiasi.	\N	1	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
b9c4ef96-b192-417c-ad03-4464ea4bd808	b34da4ce-b23a-449e-ad96-f2b738cbca7c	666c4222-69c1-421b-8200-a10290440162	Mempersilahkan  pasien  kembali  ke  ruang tunggu untuk menunggu hasil radiograf.	\N	1	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
1533f00e-935e-4af7-a40b-5e7897310940	b34da4ce-b23a-449e-ad96-f2b738cbca7c	c36494b4-8f30-4b6a-8020-84a37b4b80ca	SIKAP	\N	0	0	1	\N	\N	0	2	\N	\N	\N	\N	\N	\N	\N
0751e02e-3086-4d5a-8315-33731e0bbef9	b34da4ce-b23a-449e-ad96-f2b738cbca7c	fe20ae99-30ce-4cea-a454-37359f16c3bd	Inisiatif	\N	0	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
e103388c-c186-4667-b429-967acc97e7e2	b34da4ce-b23a-449e-ad96-f2b738cbca7c	7eab875a-ad52-4ff2-971b-63e30724b03c	Disiplin	\N	0	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
2ee6d840-91ad-4edb-80d0-7ec5ccb8b543	b34da4ce-b23a-449e-ad96-f2b738cbca7c	af754f5e-cdef-4660-bc34-2bc09e06bc26	Kejujuran	\N	0	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
68235e13-ebcc-4027-a296-395e69a6d331	b34da4ce-b23a-449e-ad96-f2b738cbca7c	6a89654c-909f-43e3-ab47-d39c30037418	Tanggung Jawab	\N	0	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
f00b58de-617c-42e1-9be6-91e3b3d1ca48	b34da4ce-b23a-449e-ad96-f2b738cbca7c	e63c6735-4cde-4093-98cd-0b2822c924ce	Kerjasama	\N	0	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
41896df5-b105-491e-bab3-93329e06b666	b34da4ce-b23a-449e-ad96-f2b738cbca7c	dc8f07b1-45cd-4977-8ce2-312f5455bf19	Santun terhadap Pasien	\N	0	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
733b9c9b-f05f-47c6-8432-2dea1541f826	b34da4ce-b23a-449e-ad96-f2b738cbca7c	a8e52691-7aa2-4ade-8323-e4e5495fb63b	Santun terhadap dosen	\N	0	0	1	\N	\N	0	0	\N	\N	\N	\N	\N	\N	\N
\.


--
-- TOC entry 3744 (class 0 OID 16609)
-- Dependencies: 254
-- Data for Name: type_four_trsdetailassesments; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.type_four_trsdetailassesments (id, trsassesmentid, assesmentdetailid, assesmentdescription, transactiondate, assesmentskala, assesmentscore, active, created_at, updated_at, assementvalue, kodesub) FROM stdin;
c40b8e5e-f3f4-43cb-a8ec-1cb0afd35985	aa05c4f0-5523-40ec-8ae5-18cd5064a7d6	b1a97851-1d4a-409c-8c22-c5eff6b1812e	Indikasi	\N	\N	7	1	\N	2024-04-03 13:46:34	7	0
204e0a74-777a-4259-aee6-8fe574be3991	afd29ff9-e6eb-4248-8f66-30af29d620c5	f2da3b8b-7303-43e7-829c-bd62e5f63d3f	Indikasi	\N	\N	7	1	\N	2024-04-03 14:41:22	7	0
04888748-ca95-406d-bbc8-f680805debf7	aa05c4f0-5523-40ec-8ae5-18cd5064a7d6	487e98c5-17c9-40e8-8612-820c78743e80	Preparasi	\N	\N	18	1	\N	2024-04-03 13:46:58	18	0
64e0b34f-6a59-4bad-b54c-792d4db08be3	9a98f4d3-aeb7-400f-bec3-66fbe3ccac8f	e7e3952b-2882-4ee0-99e1-dca0afebed48	Liner, Etsa dan Bonding	\N	\N	37	1	\N	2024-04-03 14:35:58	37	0
b34c30b7-c363-480d-b600-b471c44cce50	aa05c4f0-5523-40ec-8ae5-18cd5064a7d6	7e5e3e26-17d3-4817-8503-5d307c6a86e6	Isolasi daerah kerja	\N	\N	9	1	\N	2024-04-03 13:47:09	9	0
5b5767ef-fd14-4a76-9ca1-f8833b7faaa7	afd29ff9-e6eb-4248-8f66-30af29d620c5	1b6824e3-7775-493d-80f5-b67c736b32f2	Kontrol	\N	\N	8	1	\N	2024-04-03 14:42:06	8	0
1ace19d2-853f-47af-8366-b62cb520b39e	aa05c4f0-5523-40ec-8ae5-18cd5064a7d6	e7fcf8f9-a3d9-471c-9b55-8b682e20c78d	Pemasangan matriks	\N	\N	9	1	\N	2024-04-03 13:47:18	9	0
8b9aa7dc-561d-4bac-bf7e-a298e0f698b3	9a98f4d3-aeb7-400f-bec3-66fbe3ccac8f	762e0417-2ced-46e2-bd01-9b28f1b91231	Penumpatan komposit	\N	\N	37	1	\N	2024-04-03 14:36:05	37	0
92220e39-b4dc-4aa0-a695-7c549113be36	aa05c4f0-5523-40ec-8ae5-18cd5064a7d6	89231dcf-9183-406e-9b93-7dd68850986e	Liner, Etsa dan Bonding	\N	\N	36	1	\N	2024-04-03 13:47:35	36	0
11681a5e-9836-45e9-8d3c-5342ef0c4ec2	afd29ff9-e6eb-4248-8f66-30af29d620c5	821ca840-ba02-4511-bca7-51a6ea717e57	Preparasi	\N	\N	11	1	\N	2024-04-03 14:41:28	11	0
4792a745-1074-41d4-87a6-48151093ca93	aa05c4f0-5523-40ec-8ae5-18cd5064a7d6	990d3d91-bb32-411f-9ed1-6ec333e66b59	Penumpatan komposit	\N	\N	36	1	\N	2024-04-03 13:47:46	36	0
4d79d875-a943-49a5-906f-f4ef591e687a	9a98f4d3-aeb7-400f-bec3-66fbe3ccac8f	78a9dc27-194e-4bae-8756-baa5159c785d	Finishing dan polishing	\N	\N	9	1	\N	2024-04-03 14:36:16	9	0
03e8500f-a57c-456c-96b9-e5e5b9f51bd4	aa05c4f0-5523-40ec-8ae5-18cd5064a7d6	ccfd5aed-94e8-4e5c-b82f-1ade4308c99f	Finishing dan polishing	\N	\N	9	1	\N	2024-04-03 13:47:52	9	0
ebff16bf-2ef5-44cc-b4d5-ee92781c6cbe	afd29ff9-e6eb-4248-8f66-30af29d620c5	9f5b57af-6fff-4622-9e66-bb8ddb6098e6	Pekerjaan	\N	0	110	1	\N	2024-04-03 14:42:06	0	1
601895bc-1706-4e66-ad06-6b77ecef128f	aa05c4f0-5523-40ec-8ae5-18cd5064a7d6	fbf9cbdd-7b4c-458d-b1c4-6909e9f09b1d	Kontrol	\N	\N	9	1	\N	2024-04-03 13:47:57	9	0
c7a0b014-39bc-430f-8901-d26e083fe54c	aa05c4f0-5523-40ec-8ae5-18cd5064a7d6	ad962ad5-50ed-49da-94c4-e84a19f3e53b	Pekerjaan	\N	0	133	1	\N	2024-04-03 13:47:57	0	1
a75c59c3-5a2e-42a9-8298-64f83b165caa	aa05c4f0-5523-40ec-8ae5-18cd5064a7d6	70c0fc44-1e0b-49bc-89fa-b3e1772c3644	Inisiatif dan komunikasi	\N	\N	18	1	\N	2024-04-03 14:24:01	18	0
b6c39ed5-0da2-4475-ab95-a2cd8650dc51	9a98f4d3-aeb7-400f-bec3-66fbe3ccac8f	de8a1a07-d720-4ad7-bf42-846cf4eb3ac8	Kontrol	\N	\N	8	1	\N	2024-04-03 14:36:22	8	0
359473e2-6424-4e2d-9736-ed0fdbdc7605	aa05c4f0-5523-40ec-8ae5-18cd5064a7d6	d3334d00-dfef-4914-b734-3c8de23972e7	Disiplin	\N	\N	12	1	\N	2024-04-03 14:24:09	12	0
e052da2a-64fa-426e-a39b-839c4ccf971c	9a98f4d3-aeb7-400f-bec3-66fbe3ccac8f	636d8493-7327-46bd-b9f2-9c8b8b30e3b7	Pekerjaan	\N	0	126	1	\N	2024-04-03 14:36:22	0	1
6f80aa9a-5888-4999-aa33-4e7f52fec537	aa05c4f0-5523-40ec-8ae5-18cd5064a7d6	96caee70-548b-4552-8c82-f93e40842bc8	Kejujuran	\N	\N	15	1	\N	2024-04-03 14:24:17	15	0
eade170f-6a6a-4673-a800-54e0476a51c1	9a98f4d3-aeb7-400f-bec3-66fbe3ccac8f	0d802a0f-26a5-468a-9372-4d48e59dfc41	Inisiatif dan komunikasi	\N	\N	18	1	\N	2024-04-03 14:36:36	18	0
c3d30244-1ddf-47b4-99a1-8112df33c224	aa05c4f0-5523-40ec-8ae5-18cd5064a7d6	a9d0b8af-8b15-4b36-8db6-83628cde8c7d	Tanggung jawab	\N	\N	15	1	\N	2024-04-03 14:24:23	15	0
9a3a5721-5316-4275-a267-6caa9e4477d0	afd29ff9-e6eb-4248-8f66-30af29d620c5	f67bdfad-86ad-415d-9bcd-d0bc28997d23	Isolasi daerah kerja	\N	\N	8	1	\N	2024-04-03 14:41:33	8	0
eb3e64cb-abde-4c5d-a6fa-5bc21ea62d45	aa05c4f0-5523-40ec-8ae5-18cd5064a7d6	6a95bf2d-a427-4712-b5d3-6471b3717a9a	Sopan santun	\N	\N	15	1	\N	2024-04-03 14:24:30	15	0
d5b75a79-ec0a-4193-8a7c-2d29a9e1e195	aa05c4f0-5523-40ec-8ae5-18cd5064a7d6	c3ecef61-deb0-49c6-9e6d-d02bb5930ef9	Sikap	\N	0	75	1	\N	2024-04-03 14:24:30	0	2
e121437c-3d92-42f5-a8cc-edc7890d5293	9a98f4d3-aeb7-400f-bec3-66fbe3ccac8f	b01d7ab9-48c0-42d6-a73a-3e89e1700662	Indikasi	\N	\N	8	1	\N	2024-04-03 14:35:12	8	0
cdd5173b-7876-4478-b314-7e02f40756a0	9a98f4d3-aeb7-400f-bec3-66fbe3ccac8f	374fc9f3-503e-4558-ba94-7f2688a5e7a8	Disiplin	\N	\N	18	1	\N	2024-04-03 14:36:50	18	0
f1107494-ce7d-4f7d-ab5f-4544b59ccc23	9a98f4d3-aeb7-400f-bec3-66fbe3ccac8f	a88aa365-5367-43b7-b8b2-6cc50ddd19fd	Preparasi	\N	\N	18	1	\N	2024-04-03 14:35:24	18	0
3cd83385-695d-4c93-b6c1-b2fe70af622d	afd29ff9-e6eb-4248-8f66-30af29d620c5	6905038a-8c9f-4461-b2ae-785dad0a5db0	Inisiatif dan komunikasi	\N	\N	16	1	\N	2024-04-03 14:42:19	16	0
1f2517f2-b2e5-43f8-8527-a6b54a065c27	9a98f4d3-aeb7-400f-bec3-66fbe3ccac8f	e1e03caa-1b2e-4a2d-a3b2-0cd8ffb42915	Isolasi daerah kerja	\N	\N	9	1	\N	2024-04-03 14:35:30	9	0
f53e7306-e558-4ff0-baef-e958d14578ad	afd29ff9-e6eb-4248-8f66-30af29d620c5	70dc5f2f-ea05-4bd2-8be6-da5eb8e2a701	Pemasangan matriks	\N	\N	8	1	\N	2024-04-03 14:41:39	8	0
f90b286f-bf85-44c5-a287-b8d9f09a5e2d	9a98f4d3-aeb7-400f-bec3-66fbe3ccac8f	b43c94c8-3ec1-43fc-a443-906ceee457d2	Kejujuran	\N	\N	18	1	\N	2024-04-03 14:36:57	18	0
a21df62c-9bf5-4e29-9347-87accf069727	9a98f4d3-aeb7-400f-bec3-66fbe3ccac8f	ea32d02d-5aa2-49ff-80e5-be78ae9eb218	Tanggung jawab	\N	\N	18	1	\N	2024-04-03 14:37:05	18	0
c74fb257-1821-4b17-821d-e92d3c5c1a64	afd29ff9-e6eb-4248-8f66-30af29d620c5	ad045742-7f7c-472b-9d71-9ea56c500205	Liner, Etsa dan Bonding	\N	\N	27	1	\N	2024-04-03 14:41:46	27	0
0db6b229-8c84-4fb6-8686-eea554117808	9a98f4d3-aeb7-400f-bec3-66fbe3ccac8f	e3d23c0f-6f02-43e0-8b8e-cdc3b222f425	Sopan santun	\N	\N	18	1	\N	2024-04-03 14:37:11	18	0
50f966e5-b52d-47a1-a304-07f8b03dfce2	9a98f4d3-aeb7-400f-bec3-66fbe3ccac8f	208de0d0-2f2f-489c-8009-a4f64b98d76f	Sikap	\N	0	90	1	\N	2024-04-03 14:37:11	0	2
4d6cfb31-df3c-470d-a10e-0169f010cce7	afd29ff9-e6eb-4248-8f66-30af29d620c5	d6799d41-f2db-45be-838c-94cf13d5b362	Disiplin	\N	\N	16	1	\N	2024-04-03 14:42:25	16	0
f5b9587f-4350-4881-85f9-11e45219aaa8	afd29ff9-e6eb-4248-8f66-30af29d620c5	9dca9bb2-1f3d-4aff-816e-e10b631da4bd	Penumpatan komposit	\N	\N	34	1	\N	2024-04-03 14:41:55	34	0
23a6f137-56a6-431e-806c-093f463317af	afd29ff9-e6eb-4248-8f66-30af29d620c5	54232435-4002-4d49-8acc-61d19637f95b	Finishing dan polishing	\N	\N	7	1	\N	2024-04-03 14:42:01	7	0
74e787a5-1818-4956-bacb-fe8db3608745	afd29ff9-e6eb-4248-8f66-30af29d620c5	30a52211-b9e8-42b0-869e-f5f4a0d937e0	Kejujuran	\N	\N	16	1	\N	2024-04-03 14:42:32	16	0
fccca79d-c2fb-4109-9ec3-d6c67cb3ba27	afd29ff9-e6eb-4248-8f66-30af29d620c5	b109dd6e-5174-438a-bb4d-dcbf7a064885	Tanggung jawab	\N	\N	16	1	\N	2024-04-03 14:42:38	16	0
3910a567-1a66-4c63-b2f0-adac94bd2d6d	b458ab26-728c-49ae-8415-718a07f6ebc9	85a261bc-7f1f-40b5-bc7f-41042b34eed3	Indikasi	\N	\N	7	1	\N	2024-04-03 14:44:12	7	0
cdb12add-0885-401b-b9a2-6d3307604d30	afd29ff9-e6eb-4248-8f66-30af29d620c5	cfbf1a94-88d4-4b07-97e2-38e8cece4f59	Sopan santun	\N	\N	16	1	\N	2024-04-03 14:42:43	16	0
48876dea-3226-415f-b119-0f1fadefa4fc	afd29ff9-e6eb-4248-8f66-30af29d620c5	f9a2a144-2851-46c6-87e5-38ddc286069f	Sikap	\N	0	80	1	\N	2024-04-03 14:42:43	0	2
02cdd505-b6c2-4aa1-a218-1399d5ca61f2	b458ab26-728c-49ae-8415-718a07f6ebc9	7a746166-d187-4596-b051-f84823ca71b4	Isolasi daerah kerja	\N	\N	8	1	\N	2024-04-03 14:44:22	8	0
41083d17-de5c-4b1f-a4a4-894107805ad3	b458ab26-728c-49ae-8415-718a07f6ebc9	5993947d-d554-439a-9d82-aeb572937012	Preparasi	\N	\N	11	1	\N	2024-04-03 14:44:17	11	0
64729390-aeb7-45fa-8ef7-c0728814c0de	b458ab26-728c-49ae-8415-718a07f6ebc9	f9527bcb-f9c1-487b-b1d0-f01820697c75	Pemasangan matriks	\N	\N	8	1	\N	2024-04-03 14:44:27	8	0
f46a9e82-9f87-4cf5-bb55-56ab4ebd230a	b458ab26-728c-49ae-8415-718a07f6ebc9	f7f57568-c3db-4d4a-b351-fbe24b783da5	Liner, Etsa dan Bonding	\N	\N	23	1	\N	2024-04-03 14:44:36	23	0
98b87d72-cff8-4247-a67c-091ee02662d6	b458ab26-728c-49ae-8415-718a07f6ebc9	cbf8684a-e8bb-41bc-b6d4-ab4dd67a9ace	Penumpatan komposit	\N	\N	23	1	\N	2024-04-03 14:44:42	23	0
48637a1f-d5a4-4ed4-97f6-6d37d89abb2a	b458ab26-728c-49ae-8415-718a07f6ebc9	e8b6a089-01e8-4208-be8c-9566e240a5a8	Finishing dan polishing	\N	\N	7	1	\N	2024-04-03 14:44:47	7	0
9717ed63-983a-4da7-a077-8dd78c1add99	b458ab26-728c-49ae-8415-718a07f6ebc9	6b646e18-0a7c-455e-80db-585c70b92ece	Kontrol	\N	\N	7	1	\N	2024-04-03 14:44:52	7	0
8132f575-da27-4390-a54b-5d54bd5f110f	b458ab26-728c-49ae-8415-718a07f6ebc9	1b2fc707-faea-4025-ad4e-887a8b51daab	Inisiatif dan komunikasi	\N	\N	14	1	\N	2024-04-03 14:45:04	14	0
d1575a26-bdf4-4f9b-b0bb-a4f5b27a3fb2	b458ab26-728c-49ae-8415-718a07f6ebc9	f52a0eb1-2e6c-4e31-9bff-6e349ddea80b	Pekerjaan	\N	0	94	1	\N	2024-04-03 14:44:52	0	1
27ff7a5a-c3fa-4a76-9dc2-ad09705b50fa	b458ab26-728c-49ae-8415-718a07f6ebc9	eec3ccb3-ccd8-4267-99bd-0f0b7802d9c3	Kejujuran	\N	\N	14	1	\N	2024-04-03 14:45:14	14	0
08e5df90-df49-4a17-a576-afd8f0cc3b0c	b458ab26-728c-49ae-8415-718a07f6ebc9	4958ab82-eefd-4593-b69a-572f8ef08002	Disiplin	\N	\N	14	1	\N	2024-04-03 14:45:09	14	0
14a6b855-f610-4bc9-b698-df1e09b652ba	b458ab26-728c-49ae-8415-718a07f6ebc9	aa4172e8-74da-491b-be2c-d73a2524ca39	Tanggung jawab	\N	\N	14	1	\N	2024-04-03 14:45:20	14	0
2ad30d79-c9e4-4c01-87ad-528147748886	b458ab26-728c-49ae-8415-718a07f6ebc9	68a7cc09-3d36-4475-b03d-c6f6906cdda3	Sopan santun	\N	\N	14	1	\N	2024-04-03 14:45:25	14	0
24e40017-160e-4ced-bcd5-74037839448e	b458ab26-728c-49ae-8415-718a07f6ebc9	38a3425c-be31-462b-8b2e-2174283a866d	Sikap	\N	0	70	1	\N	2024-04-03 14:45:25	0	2
911b6fff-f007-449e-9183-32b861b3628b	a2553d01-639d-4bb6-9975-e7842f0537dd	0e3b0bb3-55a8-452c-9d82-b6d1482aaa8d	Indikasi	\N	\N	8	1	\N	2024-04-03 14:46:22	8	0
9524ed68-016d-4682-a47a-59759fb22f37	a2553d01-639d-4bb6-9975-e7842f0537dd	f265c312-f909-411b-a168-323bbd880ce6	Preparasi	\N	\N	12	1	\N	2024-04-03 14:46:28	12	0
a5367886-a022-4434-8ede-ccf229f389c9	a2553d01-639d-4bb6-9975-e7842f0537dd	c18798e0-f869-40ff-a5ac-9cf962c71e9c	Isolasi daerah kerja	\N	\N	8	1	\N	2024-04-03 14:46:33	8	0
bc700549-9d41-453f-908a-212c137ea9d4	a2553d01-639d-4bb6-9975-e7842f0537dd	adb18ca1-3b47-4d4f-a129-5b0a86c956c2	Aplikasi Dentin Conditioner	\N	\N	8	1	\N	2024-04-03 14:46:39	8	0
51da9acf-027d-4495-a6eb-2673b69bfde3	a2553d01-639d-4bb6-9975-e7842f0537dd	70b07729-8d64-41a0-bf0a-b1718dbdcc0c	Penumpatan GIC/RMGIC	\N	\N	23	1	\N	2024-04-03 14:46:45	23	0
533787e2-73c1-4e61-91c9-79755b2bbb51	a2553d01-639d-4bb6-9975-e7842f0537dd	345f9246-6d54-4c35-a470-bab0fb58dea0	Pemolesan	\N	\N	13	1	\N	2024-04-03 14:46:53	13	0
d237d771-0756-453f-91b2-d86cb940e95c	a2553d01-639d-4bb6-9975-e7842f0537dd	be2f6245-9756-4fc7-961c-85226774f79b	Kontrol	\N	\N	8	1	\N	2024-04-03 14:46:58	8	0
ede4acea-1bd1-4978-95b1-66325bcf5017	a2553d01-639d-4bb6-9975-e7842f0537dd	5b359e63-25fc-4d41-b0bc-09007cc5048b	Pekerjaan	\N	0	80	1	\N	2024-04-03 14:46:58	0	1
b0e09ba4-456f-44a7-9dca-5a644b27ef77	a2553d01-639d-4bb6-9975-e7842f0537dd	197a4c9b-fe61-4859-b9aa-530bb2be1d63	Inisiatif dan komunikasi	\N	\N	15	1	\N	2024-04-03 14:47:09	15	0
3d180c9b-bbef-4416-b716-9f53d959cfcb	a2553d01-639d-4bb6-9975-e7842f0537dd	81b54585-713c-4ff7-997e-ea33d5d14882	Disiplin	\N	\N	12	1	\N	2024-04-03 14:47:22	12	0
20ccd780-658d-43ea-978e-148fef04adcd	a2553d01-639d-4bb6-9975-e7842f0537dd	f8738c1c-3929-4d95-877c-116028337d72	Kejujuran	\N	\N	16	1	\N	2024-04-03 14:47:28	16	0
9f455c68-f0a7-4f9e-91b4-6334f799816c	a2553d01-639d-4bb6-9975-e7842f0537dd	4f94a4dd-68e6-48ca-a861-a5108856d11b	Tanggung jawab	\N	\N	17	1	\N	2024-04-03 14:47:35	17	0
a3790a72-2d20-4ad1-9a4f-870dcbd77253	a2553d01-639d-4bb6-9975-e7842f0537dd	db7ffddf-f314-438e-883c-8d5a9da822b9	Sopan santun	\N	\N	17	1	\N	2024-04-03 14:47:41	17	0
a2b8a302-8fc5-40be-bf17-7e5ae3d0d34f	a2553d01-639d-4bb6-9975-e7842f0537dd	181378d2-53ea-4382-acb0-b520f082c898	Sikap	\N	0	77	1	\N	2024-04-03 14:47:41	0	2
b2078564-9c8e-4985-a6d8-b637297cf563	6b41c5e8-c113-46bc-bbc6-e580b286c88a	f52a0eb1-2e6c-4e31-9bff-6e349ddea80b	Pekerjaan	\N	0	0	1	\N	\N	0	1
06c5244c-f1cf-4777-959c-92aa00a1c08e	6b41c5e8-c113-46bc-bbc6-e580b286c88a	85a261bc-7f1f-40b5-bc7f-41042b34eed3	Indikasi	\N	8	0	1	\N	\N	0	0
49d5570e-494d-4287-a01f-df333a4a4994	6b41c5e8-c113-46bc-bbc6-e580b286c88a	5993947d-d554-439a-9d82-aeb572937012	Preparasi	\N	20	0	1	\N	\N	0	0
6a339cf0-0446-4c32-adad-211e3ec27449	6b41c5e8-c113-46bc-bbc6-e580b286c88a	7a746166-d187-4596-b051-f84823ca71b4	Isolasi daerah kerja	\N	9	0	1	\N	\N	0	0
0defaded-0dd1-48c3-8a94-7ad236b05bbb	6b41c5e8-c113-46bc-bbc6-e580b286c88a	f9527bcb-f9c1-487b-b1d0-f01820697c75	Pemasangan matriks	\N	9	0	1	\N	\N	0	0
c5f9de4a-68c0-4783-9ffe-41ef6721e661	6b41c5e8-c113-46bc-bbc6-e580b286c88a	f7f57568-c3db-4d4a-b351-fbe24b783da5	Liner, Etsa dan Bonding	\N	36	0	1	\N	\N	0	0
eb259d14-3e2f-4b8b-9735-e01e84852461	6b41c5e8-c113-46bc-bbc6-e580b286c88a	cbf8684a-e8bb-41bc-b6d4-ab4dd67a9ace	Penumpatan komposit	\N	36	0	1	\N	\N	0	0
eb29fee8-79ee-41a6-9946-0aedfacccd98	6b41c5e8-c113-46bc-bbc6-e580b286c88a	e8b6a089-01e8-4208-be8c-9566e240a5a8	Finishing dan polishing	\N	9	0	1	\N	\N	0	0
d402d8d2-0736-470c-bb00-e57c5c4b6b14	6b41c5e8-c113-46bc-bbc6-e580b286c88a	6b646e18-0a7c-455e-80db-585c70b92ece	Kontrol	\N	9	0	1	\N	\N	0	0
cfeb0d1c-e19f-41ac-aeb8-b555b3f25160	6b41c5e8-c113-46bc-bbc6-e580b286c88a	38a3425c-be31-462b-8b2e-2174283a866d	Sikap	\N	0	0	1	\N	\N	0	2
330ee08d-8b0e-437a-8bb6-2f211e575b62	6b41c5e8-c113-46bc-bbc6-e580b286c88a	1b2fc707-faea-4025-ad4e-887a8b51daab	Inisiatif dan komunikasi	\N	20	0	1	\N	\N	0	0
64accae4-37ac-415b-9a0a-07326de35fc7	6b41c5e8-c113-46bc-bbc6-e580b286c88a	4958ab82-eefd-4593-b69a-572f8ef08002	Disiplin	\N	20	0	1	\N	\N	0	0
c080f9b0-ab3e-47ba-89b0-4b4df9aee9ae	6b41c5e8-c113-46bc-bbc6-e580b286c88a	eec3ccb3-ccd8-4267-99bd-0f0b7802d9c3	Kejujuran	\N	20	0	1	\N	\N	0	0
46f5f252-d7dd-4d14-96a9-7ead23768ee0	6b41c5e8-c113-46bc-bbc6-e580b286c88a	aa4172e8-74da-491b-be2c-d73a2524ca39	Tanggung jawab	\N	20	0	1	\N	\N	0	0
85bab6da-5231-4d31-a9db-de7badab7cc6	6b41c5e8-c113-46bc-bbc6-e580b286c88a	68a7cc09-3d36-4475-b03d-c6f6906cdda3	Sopan santun	\N	20	0	1	\N	\N	0	0
658194d2-9fe3-4f1c-97c6-24030c8d462e	c5ed052d-cfed-4151-ab46-43c26ae3601d	636d8493-7327-46bd-b9f2-9c8b8b30e3b7	Pekerjaan	\N	0	0	1	\N	\N	0	1
46148851-17d8-4d27-b37e-ca307783ae8f	c5ed052d-cfed-4151-ab46-43c26ae3601d	b01d7ab9-48c0-42d6-a73a-3e89e1700662	Indikasi	\N	10	0	1	\N	\N	0	0
e8b8826e-c17e-45d4-b5f6-fafbaf1c026d	c5ed052d-cfed-4151-ab46-43c26ae3601d	a88aa365-5367-43b7-b8b2-6cc50ddd19fd	Preparasi	\N	20	0	1	\N	\N	0	0
9f89571b-a3e6-486b-90a7-736e3d796cbb	c5ed052d-cfed-4151-ab46-43c26ae3601d	e1e03caa-1b2e-4a2d-a3b2-0cd8ffb42915	Isolasi daerah kerja	\N	10	0	1	\N	\N	0	0
50611828-4945-4095-a1b5-a16942006089	c5ed052d-cfed-4151-ab46-43c26ae3601d	e7e3952b-2882-4ee0-99e1-dca0afebed48	Liner, Etsa dan Bonding	\N	40	0	1	\N	\N	0	0
a415d3f4-3c3d-4a70-8718-489125b8c9c4	c5ed052d-cfed-4151-ab46-43c26ae3601d	762e0417-2ced-46e2-bd01-9b28f1b91231	Penumpatan komposit	\N	40	0	1	\N	\N	0	0
52159726-3f39-4aa8-b5c7-29761867b03b	c5ed052d-cfed-4151-ab46-43c26ae3601d	78a9dc27-194e-4bae-8756-baa5159c785d	Finishing dan polishing	\N	10	0	1	\N	\N	0	0
45e885ec-6463-49a7-ae09-11cde0b30beb	c5ed052d-cfed-4151-ab46-43c26ae3601d	de8a1a07-d720-4ad7-bf42-846cf4eb3ac8	Kontrol	\N	10	0	1	\N	\N	0	0
3beaa96d-1c47-433c-b917-8dee836fc9f3	c5ed052d-cfed-4151-ab46-43c26ae3601d	208de0d0-2f2f-489c-8009-a4f64b98d76f	Sikap	\N	0	0	1	\N	\N	0	2
7d4a162a-7e5f-45c2-abbd-6a970723b36e	c5ed052d-cfed-4151-ab46-43c26ae3601d	0d802a0f-26a5-468a-9372-4d48e59dfc41	Inisiatif dan komunikasi	\N	20	0	1	\N	\N	0	0
073adff5-0647-46c3-9609-afbd3fa95922	c5ed052d-cfed-4151-ab46-43c26ae3601d	374fc9f3-503e-4558-ba94-7f2688a5e7a8	Disiplin	\N	20	0	1	\N	\N	0	0
be99ade2-a5ee-456f-a098-7c66d2513229	c5ed052d-cfed-4151-ab46-43c26ae3601d	b43c94c8-3ec1-43fc-a443-906ceee457d2	Kejujuran	\N	20	0	1	\N	\N	0	0
dbaf1507-ccb7-4834-af86-ad3d1bd2cf24	c5ed052d-cfed-4151-ab46-43c26ae3601d	ea32d02d-5aa2-49ff-80e5-be78ae9eb218	Tanggung jawab	\N	20	0	1	\N	\N	0	0
7c30d13b-32ff-49a6-a8f6-288cf1649ede	c5ed052d-cfed-4151-ab46-43c26ae3601d	e3d23c0f-6f02-43e0-8b8e-cdc3b222f425	Sopan santun	\N	20	0	1	\N	\N	0	0
08c53c19-a1fc-4338-8950-93ffc752f4ff	ff6f38fe-01b4-4509-b348-f82af0320322	636d8493-7327-46bd-b9f2-9c8b8b30e3b7	Pekerjaan	\N	0	0	1	\N	\N	0	1
231adce9-4a57-4a83-aa2f-ccbed8ff7304	ff6f38fe-01b4-4509-b348-f82af0320322	b01d7ab9-48c0-42d6-a73a-3e89e1700662	Indikasi	\N	10	0	1	\N	\N	0	0
fa347139-2e36-48c2-abbd-e482b5ac4770	ff6f38fe-01b4-4509-b348-f82af0320322	a88aa365-5367-43b7-b8b2-6cc50ddd19fd	Preparasi	\N	20	0	1	\N	\N	0	0
47c1411c-288c-4303-8f36-94c089c11686	ff6f38fe-01b4-4509-b348-f82af0320322	e1e03caa-1b2e-4a2d-a3b2-0cd8ffb42915	Isolasi daerah kerja	\N	10	0	1	\N	\N	0	0
bd3519c9-df6d-43cc-be9c-754c48018340	ff6f38fe-01b4-4509-b348-f82af0320322	e7e3952b-2882-4ee0-99e1-dca0afebed48	Liner, Etsa dan Bonding	\N	40	0	1	\N	\N	0	0
40107476-80e3-4894-88cc-cfec354c4139	ff6f38fe-01b4-4509-b348-f82af0320322	762e0417-2ced-46e2-bd01-9b28f1b91231	Penumpatan komposit	\N	40	0	1	\N	\N	0	0
b50bffe2-cd88-44bf-9116-d443e06e9143	ff6f38fe-01b4-4509-b348-f82af0320322	78a9dc27-194e-4bae-8756-baa5159c785d	Finishing dan polishing	\N	10	0	1	\N	\N	0	0
a43d9dc3-176c-4d7f-8b89-362e5afa7fb3	ff6f38fe-01b4-4509-b348-f82af0320322	de8a1a07-d720-4ad7-bf42-846cf4eb3ac8	Kontrol	\N	10	0	1	\N	\N	0	0
208f8cd3-70f4-4759-8f9a-4cf402f349c7	ff6f38fe-01b4-4509-b348-f82af0320322	208de0d0-2f2f-489c-8009-a4f64b98d76f	Sikap	\N	0	0	1	\N	\N	0	2
91c5df02-773b-4098-8a39-bf5287465f9c	ff6f38fe-01b4-4509-b348-f82af0320322	0d802a0f-26a5-468a-9372-4d48e59dfc41	Inisiatif dan komunikasi	\N	20	0	1	\N	\N	0	0
0c81fbf8-19e2-4f0f-9ee2-c691e0bd6b3f	ff6f38fe-01b4-4509-b348-f82af0320322	374fc9f3-503e-4558-ba94-7f2688a5e7a8	Disiplin	\N	20	0	1	\N	\N	0	0
f5e91b9c-0f08-451a-8637-f161daabb98d	ff6f38fe-01b4-4509-b348-f82af0320322	b43c94c8-3ec1-43fc-a443-906ceee457d2	Kejujuran	\N	20	0	1	\N	\N	0	0
56b4bd36-07f3-46d0-a7df-8215272e7482	ff6f38fe-01b4-4509-b348-f82af0320322	ea32d02d-5aa2-49ff-80e5-be78ae9eb218	Tanggung jawab	\N	20	0	1	\N	\N	0	0
fab373eb-dfbb-4b4c-9c76-8e8605a64d3a	ff6f38fe-01b4-4509-b348-f82af0320322	e3d23c0f-6f02-43e0-8b8e-cdc3b222f425	Sopan santun	\N	20	0	1	\N	\N	0	0
c9d57299-3d2b-4653-84b6-dce00fcb45b0	795c02a4-5504-48ef-bc59-80b4488ac114	7a746166-d187-4596-b051-f84823ca71b4	Isolasi daerah kerja	\N	9	0	1	\N	\N	0	0
b2736655-6ccb-4279-a0f1-aa8e1679f144	795c02a4-5504-48ef-bc59-80b4488ac114	f9527bcb-f9c1-487b-b1d0-f01820697c75	Pemasangan matriks	\N	9	0	1	\N	\N	0	0
56e5300d-4903-44f5-8789-1f27312bdc5f	795c02a4-5504-48ef-bc59-80b4488ac114	f7f57568-c3db-4d4a-b351-fbe24b783da5	Liner, Etsa dan Bonding	\N	36	0	1	\N	\N	0	0
2990c045-fc1f-417a-82ae-92054e51559d	795c02a4-5504-48ef-bc59-80b4488ac114	cbf8684a-e8bb-41bc-b6d4-ab4dd67a9ace	Penumpatan komposit	\N	36	0	1	\N	\N	0	0
e54f8dbe-96c0-48bb-80ca-911a3455502a	795c02a4-5504-48ef-bc59-80b4488ac114	e8b6a089-01e8-4208-be8c-9566e240a5a8	Finishing dan polishing	\N	9	0	1	\N	\N	0	0
fa4671ab-2086-46e8-842e-a3ffcf79a7e5	795c02a4-5504-48ef-bc59-80b4488ac114	6b646e18-0a7c-455e-80db-585c70b92ece	Kontrol	\N	9	0	1	\N	\N	0	0
70a5ea9d-a63b-4ae8-8147-f8e0707cfa7f	795c02a4-5504-48ef-bc59-80b4488ac114	38a3425c-be31-462b-8b2e-2174283a866d	Sikap	\N	0	0	1	\N	\N	0	2
3e3f89ac-2852-4566-ae4f-3033d5725adb	795c02a4-5504-48ef-bc59-80b4488ac114	1b2fc707-faea-4025-ad4e-887a8b51daab	Inisiatif dan komunikasi	\N	20	0	1	\N	\N	0	0
f5ab2328-4509-4d47-bc62-431b8bd57cff	795c02a4-5504-48ef-bc59-80b4488ac114	4958ab82-eefd-4593-b69a-572f8ef08002	Disiplin	\N	20	0	1	\N	\N	0	0
6ddf0678-49e1-43b1-8bec-cb919fb34e04	795c02a4-5504-48ef-bc59-80b4488ac114	eec3ccb3-ccd8-4267-99bd-0f0b7802d9c3	Kejujuran	\N	20	0	1	\N	\N	0	0
c130fb85-847c-45ec-af61-7a411a0f3634	795c02a4-5504-48ef-bc59-80b4488ac114	aa4172e8-74da-491b-be2c-d73a2524ca39	Tanggung jawab	\N	20	0	1	\N	\N	0	0
15d3e4b3-0106-4352-90df-b32e76e1844f	795c02a4-5504-48ef-bc59-80b4488ac114	68a7cc09-3d36-4475-b03d-c6f6906cdda3	Sopan santun	\N	20	0	1	\N	\N	0	0
f44e8473-e83b-4694-a590-f0ac7e64cf9b	795c02a4-5504-48ef-bc59-80b4488ac114	5993947d-d554-439a-9d82-aeb572937012	Preparasi	\N	\N	10	1	\N	2024-04-20 20:22:02	10	0
a749cde7-4940-4b3a-889e-8cc2c7245f35	795c02a4-5504-48ef-bc59-80b4488ac114	85a261bc-7f1f-40b5-bc7f-41042b34eed3	Indikasi	\N	\N	6	1	\N	2024-04-20 20:21:52	6	0
a4e233c7-0c7f-44f2-baeb-9f3f8bd809f2	795c02a4-5504-48ef-bc59-80b4488ac114	f52a0eb1-2e6c-4e31-9bff-6e349ddea80b	Pekerjaan	\N	0	16	1	\N	2024-04-20 20:22:02	0	1
ab700a34-b145-4a86-ae14-76425bb59ea4	aa81ee4d-ad8f-42f1-ae71-cf3d5e6b8eb4	f265c312-f909-411b-a168-323bbd880ce6	Preparasi	\N	20	0	1	\N	\N	0	0
74557218-6f44-4f9e-876e-0ad3b65e211d	aa81ee4d-ad8f-42f1-ae71-cf3d5e6b8eb4	c18798e0-f869-40ff-a5ac-9cf962c71e9c	Isolasi daerah kerja	\N	10	0	1	\N	\N	0	0
553a2d28-3d03-4d69-b1ce-364b39a0a2af	aa81ee4d-ad8f-42f1-ae71-cf3d5e6b8eb4	adb18ca1-3b47-4d4f-a129-5b0a86c956c2	Aplikasi Dentin Conditioner	\N	10	0	1	\N	\N	0	0
4f4fbf46-ee83-46b9-9d39-02ce68c5693e	aa81ee4d-ad8f-42f1-ae71-cf3d5e6b8eb4	70b07729-8d64-41a0-bf0a-b1718dbdcc0c	Penumpatan GIC/RMGIC	\N	25	0	1	\N	\N	0	0
53fade78-d7d9-4fd2-a8bb-206e367b4f75	aa81ee4d-ad8f-42f1-ae71-cf3d5e6b8eb4	345f9246-6d54-4c35-a470-bab0fb58dea0	Pemolesan	\N	15	0	1	\N	\N	0	0
9abf44c9-2525-4086-bfca-357c61da5a6c	aa81ee4d-ad8f-42f1-ae71-cf3d5e6b8eb4	be2f6245-9756-4fc7-961c-85226774f79b	Kontrol	\N	10	0	1	\N	\N	0	0
32582713-3f8d-413c-aa0e-57dc09fc3e1d	aa81ee4d-ad8f-42f1-ae71-cf3d5e6b8eb4	181378d2-53ea-4382-acb0-b520f082c898	Sikap	\N	0	0	1	\N	\N	0	2
79f9c771-623a-4d25-8cf8-efb8bfa4cb42	aa81ee4d-ad8f-42f1-ae71-cf3d5e6b8eb4	197a4c9b-fe61-4859-b9aa-530bb2be1d63	Inisiatif dan komunikasi	\N	20	0	1	\N	\N	0	0
cca7bb6b-55c1-43d5-a907-7a0234e233ce	aa81ee4d-ad8f-42f1-ae71-cf3d5e6b8eb4	81b54585-713c-4ff7-997e-ea33d5d14882	Disiplin	\N	20	0	1	\N	\N	0	0
40122264-6356-4c34-b15a-526158f52d71	aa81ee4d-ad8f-42f1-ae71-cf3d5e6b8eb4	f8738c1c-3929-4d95-877c-116028337d72	Kejujuran	\N	20	0	1	\N	\N	0	0
de23a1b3-1135-4e92-b4ee-d86ab43ecd5c	aa81ee4d-ad8f-42f1-ae71-cf3d5e6b8eb4	4f94a4dd-68e6-48ca-a861-a5108856d11b	Tanggung jawab	\N	20	0	1	\N	\N	0	0
daa0f27e-b41e-4685-9eb5-4ac57c275c45	aa81ee4d-ad8f-42f1-ae71-cf3d5e6b8eb4	db7ffddf-f314-438e-883c-8d5a9da822b9	Sopan santun	\N	20	0	1	\N	\N	0	0
2658e049-dd7e-4a71-a0b9-9f6aee824a97	aa81ee4d-ad8f-42f1-ae71-cf3d5e6b8eb4	0e3b0bb3-55a8-452c-9d82-b6d1482aaa8d	Indikasi	\N	\N	6	1	\N	2024-04-20 20:24:20	6	0
e9c2122d-8916-488a-8ccf-78c0397d46b9	aa81ee4d-ad8f-42f1-ae71-cf3d5e6b8eb4	5b359e63-25fc-4d41-b0bc-09007cc5048b	Pekerjaan	\N	0	6	1	\N	2024-04-20 20:24:20	0	1
\.


--
-- TOC entry 3742 (class 0 OID 16589)
-- Dependencies: 250
-- Data for Name: type_one_control_trsdetailassesments; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.type_one_control_trsdetailassesments (id, trsassesmentid, assesmentdetailid, assesmentdescription, transactiondate, controlaction, assementvalue, active, created_at, updated_at, kodesub) FROM stdin;
ceda08a1-52bd-43d8-9c32-a0e23b586468	cbc76149-33b7-4b54-a4ef-ca0576195864	3f8c9b5a-1b5a-4c28-b2f7-34a5df25b5e2	Kontrol	\N		0	1	\N	\N	\N
d7c8ac97-6201-43b3-8688-b1f4e9eda9ed	cbc76149-33b7-4b54-a4ef-ca0576195864	8148a45f-cb63-4dae-a3f1-348690cc9b9e	Kontrol 1	\N		0	1	\N	\N	\N
6c601823-6936-4fb3-81e9-00d7ce59f86c	cbc76149-33b7-4b54-a4ef-ca0576195864	3647b343-89ff-4308-88b7-d585f66d7fc4	Kontrol 2	\N		0	1	\N	\N	\N
b696ba7d-c45a-4c20-9d29-b845f76417db	cbc76149-33b7-4b54-a4ef-ca0576195864	74a809ee-2cbd-417c-96bc-31beaaf32dbd	Kontrol 3	\N		0	1	\N	\N	\N
\.


--
-- TOC entry 3745 (class 0 OID 16619)
-- Dependencies: 256
-- Data for Name: type_one_trsdetailassesments; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.type_one_trsdetailassesments (id, trsassesmentid, assesmentdetailid, assesmentdescription, transactiondate, assesmentbobotvalue, assesmentskala, assementscore, active, created_at, updated_at, assementvalue, kodesub) FROM stdin;
ec6e80e7-9dc4-4c02-a014-caa630af5060	16101fec-a747-4b02-9766-8ee4b9fe9e11	c76a9973-0063-4980-b7ca-1015fa531316	Persiapan peralatan\nAlat tulis\nLaporan pemeriksaan pasien	\N	2	0	4	1	\N	2024-04-02 20:56:49	2	0
e797dbe4-0d19-4dc8-824e-85225a451fc5	00a77507-e7b4-443c-b191-da36a6678174	0a8c97ba-49a5-485d-89a6-f6082b223746	Persiapan peralatan dan bahan\nAlat: 2 kaca mulut, sonde, ekskavator, pinset, alat\nukur kepala	\N	1	0	1	1	\N	2024-04-02 20:59:50	1	0
aec23d85-c3a4-443d-91a6-dd110ac5b4e7	16101fec-a747-4b02-9766-8ee4b9fe9e11	2b38b658-0d26-489e-b1ca-fbcd68fa5de9	Persiapan operator\nPemasangan masker	\N	2	0	4	1	\N	2024-04-02 20:56:53	2	0
8955dd0b-9e75-43ca-849d-d45a6071b916	16101fec-a747-4b02-9766-8ee4b9fe9e11	9d0c4274-0f34-4c31-a05b-86e0eedf61f7	Identitas pasien\nData diri pasien dan operator (mhs): nama px, umur px,\nTB-BB, pekerjaan, alamat, no telp/hp	\N	4	0	4	1	\N	2024-04-02 20:57:03	1	0
6c73bef7-7e07-4b99-8c4f-1765f46513ff	00a77507-e7b4-443c-b191-da36a6678174	18a301cb-f451-49d6-8e4d-1bdb8c4df21f	Persiapan operator\nPemasangan masker terlebih dahulu kemudian\npemakaian sarung tangan	\N	1	0	1	1	\N	2024-04-02 20:59:58	1	0
557a3eef-33ae-41ce-ac57-0881442a0e77	16101fec-a747-4b02-9766-8ee4b9fe9e11	da02455a-ed49-49e5-b61e-457349177885	Keluhan utama	\N	4	0	8	1	\N	2024-04-02 20:57:07	2	0
4e732ba7-7245-401a-91a3-64fed0873f63	00a77507-e7b4-443c-b191-da36a6678174	2524772a-7b59-4c3b-945a-c951f93cf3f7	AKTIVITAS	\N	0	0	2	1	\N	2024-04-02 20:59:58	0	1
c0e4e87a-c570-480a-870e-29a68da5c585	16101fec-a747-4b02-9766-8ee4b9fe9e11	f88f8360-01bc-4fcb-9f1b-25199cac244d	Riwayat kesehatan\nRiwayat penyakit, kelainan endokrin, penyakit pada masa\nanak-anak, alergi, kelainan saluran pernapasan tindakan\noperasi, sakit berat, kebiasaan buruk, sedang dalam\nperawatan dokter.	\N	4	0	8	1	\N	2024-04-02 20:57:11	2	0
475094c4-2289-43fc-9d6c-a6fa1309d02d	00a77507-e7b4-443c-b191-da36a6678174	c5f6a876-160c-465a-a99e-b7dfd0626081	Status gizi: TB, BB, indeks massa tubuh	\N	1	0	1	1	\N	2024-04-02 21:00:10	1	0
bcecaca4-906f-4f73-9a00-4936d2a44cde	16101fec-a747-4b02-9766-8ee4b9fe9e11	9a399cdb-104e-42a3-a2cd-ceae5ae54b4e	Riwayat pertumbuhan dan perkembangan gigi	\N	6	0	6	1	\N	2024-04-02 20:57:16	1	0
1185c676-5c7e-45dc-9f2b-33f65af6b060	00a77507-e7b4-443c-b191-da36a6678174	fd3dec47-a03f-46df-bb13-b112b12fe861	Menentukan tonus mastikasi	\N	1	0	1	1	\N	2024-04-02 21:00:45	1	0
66f535a7-7446-4d9e-9715-facc9adcf9e4	16101fec-a747-4b02-9766-8ee4b9fe9e11	0a126fba-c991-40b4-a4e8-0fdc5837ca81	Kebiasaan jelek yang berkaitan dengan keluhan pasien	\N	6	0	12	1	\N	2024-04-02 20:57:19	2	0
e14bd031-0762-44e2-a3e0-7e1251189b68	00a77507-e7b4-443c-b191-da36a6678174	d08f7ded-d1f1-4dca-80c6-6d7944a472a4	Menentukan tipe kepala	\N	2	0	2	1	\N	2024-04-02 21:00:15	1	0
cb5e1018-2e6a-4d88-9f8a-c15d0b506af6	16101fec-a747-4b02-9766-8ee4b9fe9e11	a35d8d94-9851-4930-8884-1df208133570	A. Menggunakan pertanyaan-pertanyaan yang sesuai\nuntuk mendapatkan informasi yang akurat dan\nadekuat	\N	6	0	6	1	\N	2024-04-02 20:57:22	1	0
0bdc3b10-e0eb-4b18-ae74-7aef4657473f	16101fec-a747-4b02-9766-8ee4b9fe9e11	72cd5f98-81af-4bb0-a78b-7ac0d628cded	B. Memberikan respon yang sesuai terhadap isyarat\npasien, baik secara verbal maupun nonverbal	\N	4	0	8	1	\N	2024-04-02 20:57:26	2	0
2e130f8b-1c07-43e3-a9de-d60956fe97f1	00a77507-e7b4-443c-b191-da36a6678174	90c8ba3f-fde1-4b3c-b9ca-15eda62f769f	Menentukan tipe muka	\N	2	0	4	1	\N	2024-04-02 21:00:19	2	0
8271ceb7-676d-4e1a-96b8-1f011552a8e3	16101fec-a747-4b02-9766-8ee4b9fe9e11	51b12f0c-ae40-496d-9ccb-bf229a01ff94	Sikap\nSantun terhadap pasien\nSantun terhadap instruktur\nDisiplin, tepat waktu	\N	2	0	2	1	\N	2024-04-02 20:57:38	1	0
37d1d9b2-ebea-4039-a9d2-5b2a5e27cb22	16101fec-a747-4b02-9766-8ee4b9fe9e11	4f5fea87-a314-4e82-a8ec-5690b36fc346	AKTIVITAS	\N	0	0	62	1	\N	2024-04-02 20:57:38	0	1
9c219ac1-ffc3-491f-89a8-05ffb9245c39	00a77507-e7b4-443c-b191-da36a6678174	3df7dcbd-4200-4aff-a44d-63595a1f678e	Memeriksa sendi temporomandibular (TMJ)	\N	2	0	4	1	\N	2024-04-02 21:00:49	2	0
ed0fd29a-374c-4fc6-afd5-967a6993a2f6	00a77507-e7b4-443c-b191-da36a6678174	ed9eb5ed-8d1f-4446-aa83-435ac5b867fd	Menentukan tipe profil muka	\N	1	0	1	1	\N	2024-04-02 21:00:27	1	0
e9594c7a-2908-4465-aea7-10b9be8073af	00a77507-e7b4-443c-b191-da36a6678174	36e87eeb-7a6b-47a7-a85f-8109c8752708	Menentukan tonus bibir atas	\N	1	0	1	1	\N	2024-04-02 21:00:31	1	0
ed8b923c-335e-4e87-b7c9-dd15142014f9	00a77507-e7b4-443c-b191-da36a6678174	17e85269-1ed4-41a8-8ab0-f2121e996de6	Menentukan besarnya free way space	\N	1	0	1	1	\N	2024-04-02 21:00:52	1	0
27270160-9a2b-4e11-af3f-96fdef92139a	00a77507-e7b4-443c-b191-da36a6678174	e4d872eb-3a7f-4840-97d8-d3694fe82c4d	Menentukan tonus bibir bawah	\N	1	0	1	1	\N	2024-04-02 21:00:34	1	0
831a652f-f9f4-43c5-a6d0-882260053c3a	00a77507-e7b4-443c-b191-da36a6678174	745fae5a-ce62-49ce-828e-3a7f9fe44f23	Memeriksa posisi istirahat bibir	\N	1	0	1	1	\N	2024-04-02 21:00:42	1	0
eeba53e2-1721-4a53-a239-03c3683361a3	00a77507-e7b4-443c-b191-da36a6678174	0d435bb7-c875-4957-aec0-8a28a36b5941	Menentukan besarnya free way space	\N	2	0	2	1	\N	2024-04-02 21:00:55	1	0
c08bc709-e2fc-44d9-8d65-264090859471	00a77507-e7b4-443c-b191-da36a6678174	8aafae4c-7262-408e-b741-9e655f2193de	Memeriksa path of closure	\N	1	0	1	1	\N	2024-04-02 21:01:01	1	0
70113752-a6fa-474b-b000-ccb587a8c96d	00a77507-e7b4-443c-b191-da36a6678174	5bbba4b7-acd8-41ff-a86d-5f695ab489ae	Memeriksa fonetik	\N	1	0	1	1	\N	2024-04-02 21:01:12	1	0
52a28503-5f47-40d3-b0c7-d288dcd1f196	00a77507-e7b4-443c-b191-da36a6678174	06e6fb5a-cf8a-48d7-abef-b83388f6e642	Pemeriksaan Ekstra Oral	\N	0	0	21	1	\N	2024-04-02 21:01:12	0	2
5986a1dc-b716-40ab-a440-f491e28b0063	00a77507-e7b4-443c-b191-da36a6678174	88b871c6-7b69-4886-8c4f-9a1705c27f77	Memeriksa kebersihan mulut	\N	2	0	4	1	\N	2024-04-02 21:01:22	2	0
4d9083be-b500-4810-9259-3d70e1fb6616	00a77507-e7b4-443c-b191-da36a6678174	97635238-196f-4024-9159-a62963dff10c	Memeriksa gingiva dan mukosa	\N	2	0	4	1	\N	2024-04-02 21:01:25	2	0
abfa5703-cdf5-4a12-aa3c-0c4963302ea3	00a77507-e7b4-443c-b191-da36a6678174	b4e3dde7-48e4-4e23-8fb9-1c6e8be5e181	Memeriksa frenulum labii superior	\N	2	0	4	1	\N	2024-04-02 21:01:32	2	0
943d49fa-e4e9-4b49-be5b-48abee61d472	6f318b3b-728e-496f-bec6-6b89cc1d0f00	1ffbd8b6-8f9d-4bec-91f1-84ab694dc77c	Persiapan alat dan bahan: sendok cetak berbagai ukuran,\nbowl, spatula, gelas takar, bahan cetak / alginat	\N	1	0	1	1	\N	2024-04-02 21:07:57	1	0
e57522da-8463-406f-b14e-9e2adf079351	00a77507-e7b4-443c-b191-da36a6678174	21e16a5b-44c1-4521-b9a9-5b0efa9e8611	Memeriksa frenulum labii inferior	\N	2	0	4	1	\N	2024-04-02 21:01:35	2	0
df0b9aa6-49d4-47fd-9f3a-d402ff00bbcc	00a77507-e7b4-443c-b191-da36a6678174	2efbb583-153f-44b5-81dc-941dfb8c3a55	Memeriksa frenulum lingualis	\N	1	0	1	1	\N	2024-04-02 21:01:38	1	0
220c969b-cdde-4873-9307-fb113764385c	6f318b3b-728e-496f-bec6-6b89cc1d0f00	58f1ee6c-8a8b-4776-bac8-ad800d773eb9	Persiapan operator: menggunakan lab jas, name tag,\nsarung tangan, dan masker	\N	1	0	1	1	\N	2024-04-02 21:08:01	1	0
ce552a64-ccb9-4013-b80f-2cc948eb4c08	00a77507-e7b4-443c-b191-da36a6678174	2c20d576-77e5-417e-9a2a-653f8d8aba3e	Memeriksa lingua / lidah	\N	1	0	1	1	\N	2024-04-02 21:01:41	1	0
03a54b53-2c17-4a3e-9cb2-9393a9a58deb	00a77507-e7b4-443c-b191-da36a6678174	9750e20c-74df-4ce8-b2b6-f3de68c38f39	Memeriksa palatum	\N	1	0	1	1	\N	2024-04-02 21:01:44	1	0
bb273e3b-80be-40a1-8869-f088fcab366c	6f318b3b-728e-496f-bec6-6b89cc1d0f00	a991088b-3e9e-4096-a162-65203d451790	Persiapan pasien (lihat di buku panduan)	\N	2	0	4	1	\N	2024-04-02 21:08:05	2	0
4c6ac2ff-eb45-4741-bb1d-6ba6b1d48da8	00a77507-e7b4-443c-b191-da36a6678174	bbbda967-d5aa-4f89-83cd-1cde44f8fbf0	Memeriksa pola atrisi	\N	1	0	1	1	\N	2024-04-02 21:01:48	1	0
e0e630fa-5828-4fd5-8fdd-a1a5cb2d7902	00a77507-e7b4-443c-b191-da36a6678174	abf73b49-a777-4c07-b161-d9c8793b7b45	Memeriksa keadaan gigi geligi	\N	1	0	1	1	\N	2024-04-02 21:01:51	1	0
0f32ba8d-829e-4e0a-b498-a22d85ceb41b	6f318b3b-728e-496f-bec6-6b89cc1d0f00	0b870377-d283-482a-9957-ab40c87751db	Pemilihan sendok cetak	\N	1	0	1	1	\N	2024-04-02 21:08:08	1	0
892cd1f5-b240-477d-b0f7-10d17d982e46	00a77507-e7b4-443c-b191-da36a6678174	de76cdd1-4cde-476e-85e2-9c4eaeee37f8	Memeriksa keadaan gigi geligi	\N	1	0	1	1	\N	2024-04-02 21:01:55	1	0
428c0fb0-b0c3-4dd6-9844-2868b0269818	00a77507-e7b4-443c-b191-da36a6678174	465d6f95-d038-420c-a1eb-3dba5a18d23c	Memeriksa keadaan gigi geligi	\N	3	0	3	1	\N	2024-04-02 21:01:59	1	0
e5a930ff-6287-49f4-be1c-ffa5a3e67bb9	6f318b3b-728e-496f-bec6-6b89cc1d0f00	2f0a5063-a8b2-4b6c-8d34-9e68566f72d2	Instruksi kepada pasien	\N	1	0	1	1	\N	2024-04-02 21:08:12	1	0
4727f1e8-8a0a-4787-ac00-f648fee93f2b	00a77507-e7b4-443c-b191-da36a6678174	b1289ee4-4dce-4730-838a-6e13e6b3342e	Memeriksa garis tengah geligi atas	\N	2	0	2	1	\N	2024-04-02 21:02:02	1	0
077e7935-f2d8-44e0-add7-02a981646452	6f318b3b-728e-496f-bec6-6b89cc1d0f00	bdeeac41-4973-4919-934d-8ac83efe558f	Persiapan	\N	0	0	8	1	\N	2024-04-02 21:08:12	0	1
f715ce6b-54b2-4f49-b184-5ff1002b2cbb	00a77507-e7b4-443c-b191-da36a6678174	7af9bb0f-01ea-45ce-8c78-111b7d0e37ac	Memeriksa garis tengah geligi bawah	\N	2	0	2	1	\N	2024-04-02 21:02:07	1	0
002135b1-494d-46b5-af6f-df2a22bd4681	6f318b3b-728e-496f-bec6-6b89cc1d0f00	f8a6b1f8-cd90-43b6-9f99-4049611febd1	Posisi operator	\N	1	0	1	1	\N	2024-04-02 21:08:18	1	0
58f8a9f6-439f-4461-b6b1-397eba01c533	00a77507-e7b4-443c-b191-da36a6678174	224417e2-c5e4-4167-92fc-caa8bd166956	Memeriksa tonsila	\N	2	0	2	1	\N	2024-04-02 21:02:11	1	0
ec01db5e-768b-467e-a239-78567afef6cc	00a77507-e7b4-443c-b191-da36a6678174	4a472755-5467-4ba0-9f2b-5b8c680af6cc	Sikap	\N	2	0	2	1	\N	2024-04-02 21:02:14	1	0
76e65396-1b74-4dcb-90d9-780a3bd8e2bc	00a77507-e7b4-443c-b191-da36a6678174	02a1dc73-f44e-4300-89e0-bad60a70de60	Pemeriksaan intra oral	\N	0	0	33	1	\N	2024-04-02 21:02:14	0	3
c5774654-669a-40fc-af24-4403bcc08101	6f318b3b-728e-496f-bec6-6b89cc1d0f00	7fbc9063-7381-4ba3-bc18-ffd4d48d5fa5	Prosedur mencetak rahang atas	\N	0	0	14	1	\N	2024-04-02 21:08:32	0	2
195d91b1-6f7a-41bc-9966-e610a97f161a	6f318b3b-728e-496f-bec6-6b89cc1d0f00	b49997e8-52a3-49ce-b776-a0e0a4c64794	Mencetak rahang bawah (lihat di buku panduan)	\N	2	0	0	1	\N	\N	0	0
1c3fbea9-9340-4540-9228-51e2e2f1a6fd	6f318b3b-728e-496f-bec6-6b89cc1d0f00	5d50bc25-1498-4e74-8f24-6d2ae88f1479	Manipulasi bahan cetak	\N	2	0	4	1	\N	2024-04-02 21:08:21	2	0
c10a7148-3a0a-4fc7-8200-1c9272f7c9d3	6f318b3b-728e-496f-bec6-6b89cc1d0f00	52fee973-a2b5-445f-b003-1d44dfbd0d14	Mencetak rahang atas (lihat di buku panduan)	\N	2	0	4	1	\N	2024-04-02 21:08:24	2	0
4a92d7b3-0f04-4ad2-96fa-80eef28b8d8e	6f318b3b-728e-496f-bec6-6b89cc1d0f00	e705604e-70f5-41fc-8895-d54d8368fde9	Instruksi kepada pasien	\N	1	0	1	1	\N	2024-04-02 21:08:29	1	0
4f842171-7266-4d67-9e39-b4bc6d0d0aa2	6f318b3b-728e-496f-bec6-6b89cc1d0f00	2db98abb-ea89-4e03-9f52-d95104237e97	Menjelaskan kepada instruktur	\N	2	0	4	1	\N	2024-04-02 21:08:32	2	0
14168294-768d-4757-9fca-57a02ee2345c	6f318b3b-728e-496f-bec6-6b89cc1d0f00	30025f64-b9c4-4035-b3d5-124e1de879bd	Posisi operator	\N	1	0	1	1	\N	2024-04-02 21:08:36	1	0
f7d57768-8d09-4d52-992b-ed490523dfe2	07486210-f794-43b2-bac8-25e3d9e69141	b474d9fb-ee35-42b7-92e1-8cd28eec8418	Sub Total A	\N	0	0	2	1	\N	2024-04-02 21:10:53	0	1
19494e0c-7802-4893-9cce-9daf89722eba	6f318b3b-728e-496f-bec6-6b89cc1d0f00	5ad85993-9ce7-4f52-b615-3a8aa45c5f70	Manipulasi bahan cetak	\N	2	0	4	1	\N	2024-04-02 21:08:39	2	0
25df2101-22e7-4ac5-a5f1-b791cf66bd51	07486210-f794-43b2-bac8-25e3d9e69141	4a82c555-a29d-48c4-9020-5c8bdada5eee	a. Mengukur tempat yang tersedia (available space)\nRA dan RB: mengukur dengan caliper atau jangka 6 segmen\n(M1 dan P2, P1 dan C, I2 dan I1 pada sisi kiri dan kanan).	\N	2	0	4	1	\N	2024-04-02 21:11:00	2	0
854c84d8-72ea-415c-ad95-f30737627241	6f318b3b-728e-496f-bec6-6b89cc1d0f00	44157942-afdd-435e-bfa3-a030ce98c089	Instruksi kepada pasien	\N	1	0	1	1	\N	2024-04-02 21:08:43	1	0
a4390236-7c40-4df5-b711-0ac23098ff4c	f92da2e3-1d4b-4205-8ea5-d00d70d07c82	25f6de31-e5b9-4c08-b68e-60e55fc1adfe	Persiapan alat dan bahan\n‒ Alat: viewer, kertas kalkir, pensil, penghapus,\npenggaris dan busur derajat\n‒ Bahan: sefalogram	\N	2	0	4	1	\N	2024-04-02 21:13:29	2	0
c226f19d-1db1-41f6-9c88-482661ba3f65	6f318b3b-728e-496f-bec6-6b89cc1d0f00	9bd37bac-47f1-438f-8831-5e53b5b13715	Menjelaskan kepada instruktur	\N	2	0	4	1	\N	2024-04-02 21:08:46	2	0
06fd8897-79a1-47ef-abf3-182d0e2b22ec	6f318b3b-728e-496f-bec6-6b89cc1d0f00	497b63d8-3b9e-4138-bf6f-a1a2b85e34ca	Prosedur mencetak rahang bawah	\N	0	0	10	1	\N	2024-04-02 21:08:46	0	3
bdd9509f-38aa-444b-8687-72e8aff12d9f	6f318b3b-728e-496f-bec6-6b89cc1d0f00	1824dc7c-c692-487e-b878-37cd13f93d44	Hasil cetakan rahang atas	\N	8	0	16	1	\N	2024-04-02 21:08:52	2	0
1a8d0147-7d20-4cee-878e-2177ac4f65cb	07486210-f794-43b2-bac8-25e3d9e69141	176c3123-1cb9-4941-b84b-f5a7867cc44a	b. Mengukur tempat yang dibutuhkan (required space)\nMengukur dan menjumlahkan lebar mesio-distal 6 segmen\ngigi (M1 dan P2, P1 dan C, I2 dan I1 pada sisi kiri dan kanan)	\N	2	0	4	1	\N	2024-04-02 21:11:04	2	0
5af9e279-66cb-4d03-9cf0-525513966d53	6f318b3b-728e-496f-bec6-6b89cc1d0f00	0ed211f7-7e77-48d1-ae7d-98a9f22dd35c	Hasil cetakan rahang bawah	\N	8	0	16	1	\N	2024-04-02 21:08:58	2	0
fc342b79-99c4-4dc8-b6a8-f8ea50edbc91	f92da2e3-1d4b-4205-8ea5-d00d70d07c82	cc85dcc1-9a1a-4e37-9e44-eff3dd356da2	Menjelaskan interpretasi sudut-sudut orientasi pada\nanalisis sefalometri metode Steiner	\N	6	0	12	1	\N	2024-04-02 21:14:28	2	0
237eadba-1605-4283-8ff3-0a53a6fc4396	6f318b3b-728e-496f-bec6-6b89cc1d0f00	f6526707-943d-4894-a232-12e1fb7601c4	Sikap terhadap instruktur selama perawatan berlangsung	\N	2	0	4	1	\N	2024-04-02 21:09:01	2	0
4265edf4-5132-49b8-b8b0-d6a585dc7f94	6f318b3b-728e-496f-bec6-6b89cc1d0f00	0d165e87-1609-47dc-bc3c-c864a9d6c6dc	Menjelaskan kepada instruktur	\N	0	0	36	1	\N	2024-04-02 21:09:01	0	4
730e196c-3b67-4784-9266-2ae0e26f84b6	07486210-f794-43b2-bac8-25e3d9e69141	d9698059-d09a-4c63-ade1-7f044b11a59f	Persiapan alat dan bahan\n‒ Persiapan bahan: model studi RA-RB, foto periapikal/\npanoramik jika diperlukan\n‒ Persiapan alat: jangka sorong, jangka, penggaris,\npensil, penghapus	\N	1	0	1	1	\N	2024-04-02 21:10:50	1	0
4a200d32-d8db-4ef3-a3b8-4b1c2d351c44	f92da2e3-1d4b-4205-8ea5-d00d70d07c82	478434fb-e9f2-45c7-86bf-a4726482ea1e	Melakukan tracing sefalogram pada kertas kalkir	\N	7	0	14	1	\N	2024-04-02 21:13:33	2	0
192efdde-56fd-499b-9725-bebbbd2755e8	07486210-f794-43b2-bac8-25e3d9e69141	76916aff-95cf-4a68-a214-af7bcf9fcf66	Persiapan operator\n‒ Operator menjelaskan kepada instruktur cara\npengukuran diskrepansi yang akan digunakan beserta\nalasannya	\N	1	0	1	1	\N	2024-04-02 21:10:53	1	0
1f9d2cf5-3ed7-4e00-a164-f4935731a80b	07486210-f794-43b2-bac8-25e3d9e69141	f6241b71-ea0e-4571-a188-b3c98a71923e	c. Diskrepansi\nDiskrepansi setiap segmen (6): tempat yang tersedia -\ntempat yang dibutuhkan\nMenjumlah diskrepansi 6 segmen	\N	2	0	4	1	\N	2024-04-02 21:11:08	2	0
64fbb890-9453-450d-a8e2-19216045e34d	da857f86-1e75-4703-a6e8-b9453625bd6b	b9962cfa-da63-4cba-9f9c-4da023da4865	Tampak depan tanpa senyum	\N	4	0	8	1	\N	2024-04-02 21:17:32	2	0
bbdf4487-06c6-407d-8ab6-8c03c8d2a383	07486210-f794-43b2-bac8-25e3d9e69141	f575de00-42ed-41e1-b680-5744db90d135	Menjelaskan kepada instruktur\nMahasiswa mampu menganalisis dan menjelaskan hasil\npenghitungan diskrepansi kepada instruktur	\N	4	0	8	1	\N	2024-04-02 21:11:10	2	0
e0f64397-e969-4d18-8e0d-4ff08f0c652b	07486210-f794-43b2-bac8-25e3d9e69141	5051d933-2db5-47d8-a419-08cc70201bb1	Sub Total B	\N	0	0	20	1	\N	2024-04-02 21:11:10	0	2
560880b8-a76f-4c1a-992c-345f2c5dd78e	f92da2e3-1d4b-4205-8ea5-d00d70d07c82	ed621c6d-707b-4dea-a9a1-b97b8cba8753	Menentukan titik-titik orientasi analisis sefalometri\nmetode Steiner	\N	6	0	12	1	\N	2024-04-02 21:13:36	2	0
7360324f-b5a2-42a1-bf83-440c5f45128a	f92da2e3-1d4b-4205-8ea5-d00d70d07c82	a20bf6f0-5ddd-4b45-acf6-ad7521450998	Menjelaskan diagnosis berdasarkan analisis sefalometri\nmetode Steiner	\N	7	0	14	1	\N	2024-04-02 21:14:31	2	0
41c94210-e197-41c6-9d90-58729ab3f938	f92da2e3-1d4b-4205-8ea5-d00d70d07c82	fdf4d5f4-9cba-47ac-9c0d-315ccfb1de1e	Menentukan garis-garis orientasi pada analisis sefalometri\nmetode Steiner	\N	6	0	12	1	\N	2024-04-02 21:13:40	2	0
fbec806d-9503-4067-b01e-9d8e3f0b7a5d	da857f86-1e75-4703-a6e8-b9453625bd6b	10c8b9b2-a021-45e4-93f6-4140429ca167	Tampak samping profil	\N	4	0	8	1	\N	2024-04-02 21:17:43	2	0
4dd95e4f-91cf-4b2f-a444-43302e9cce03	f92da2e3-1d4b-4205-8ea5-d00d70d07c82	7b12f049-7efc-4d74-97f8-40dc74f9b517	Menentukan sudut-sudut orientasi pada analisis\nsefalometri metode Steiner	\N	6	0	12	1	\N	2024-04-02 21:13:45	2	0
66f23a99-bac1-4767-bf05-c121cf99a4af	da857f86-1e75-4703-a6e8-b9453625bd6b	2517432d-caa9-46f3-9fc5-b9d3f52a80ec	Tampak depan senyum gigi terlihat	\N	4	0	8	1	\N	2024-04-02 21:17:39	2	0
b44cde72-72f0-4ed2-9b42-040ceeba0659	f92da2e3-1d4b-4205-8ea5-d00d70d07c82	5d0852f3-56b8-49aa-8681-411ffe25d5c7	Aktivitas	\N	0	0	80	1	\N	2024-04-02 21:14:31	0	1
5a2c666f-43fb-4ffa-ac14-f5a4e9978c55	da857f86-1e75-4703-a6e8-b9453625bd6b	ea6e1e8b-774f-48f8-8911-7a9e0d94ad00	Tampak oblique kanan	\N	4	0	8	1	\N	2024-04-02 21:17:46	2	0
426b7e5f-01ea-46c8-8842-b0f17f901c2a	da857f86-1e75-4703-a6e8-b9453625bd6b	e1f6161c-9f6b-4e17-ba7c-d8c1a28da4db	Tampak oblique kiri	\N	4	0	8	1	\N	2024-04-02 21:17:49	2	0
d36cd5ed-d718-4f6f-84df-906d2c8231b5	da857f86-1e75-4703-a6e8-b9453625bd6b	071e0c08-1e3f-4e0d-af40-ebb1da894836	Tampak depan	\N	4	0	8	1	\N	2024-04-02 21:17:54	2	0
afa202be-e374-465f-85d3-a2fe2fead48b	da857f86-1e75-4703-a6e8-b9453625bd6b	90668a91-f8a8-4525-b170-a872f0290bab	Foto Wajah	\N	0	0	40	1	\N	2024-04-02 21:17:49	0	1
79732ce1-bdcc-4dbc-aab1-ca4ae483a06b	da857f86-1e75-4703-a6e8-b9453625bd6b	62e5f922-9a6d-4ffb-ad9d-8c8fc11600d1	Tampak oklusal atas	\N	4	0	8	1	\N	2024-04-02 21:18:02	2	0
016b2d7e-9eed-45f7-b1e9-c673b02acbeb	da857f86-1e75-4703-a6e8-b9453625bd6b	5a262150-7820-422f-9a60-174098b2f958	Tampak samping kiri	\N	4	0	8	1	\N	2024-04-02 21:17:58	2	0
dba2b98c-7697-4c9e-926e-30c3b7155c02	da857f86-1e75-4703-a6e8-b9453625bd6b	c3b96699-a299-4b02-a919-736693bc5c29	Foto Gigi	\N	0	0	32	1	\N	2024-04-02 21:18:09	0	2
ce3e1ad2-848b-437f-8fc2-b65266d9c1a4	da857f86-1e75-4703-a6e8-b9453625bd6b	be6ecb86-7aa3-4e38-b4a9-1dd7e20e764e	Tampak oklusal bawah	\N	4	0	8	1	\N	2024-04-02 21:18:09	2	0
b87d332b-8db0-46ac-bc68-1adcd0823001	49f95ca3-7345-44d7-adbb-bebf53ddcdec	0e7e3f96-8b2e-4a2b-94df-7e590f492a25	Diagnosis	\N	3	0	6	1	\N	2024-04-02 21:19:08	2	0
8f9b27f6-1c1d-45ce-a473-3e051fe9c16c	49f95ca3-7345-44d7-adbb-bebf53ddcdec	b2c062be-f857-4dc7-b428-b60e4bebdb7f	Menggambar desain alat lepasan di model kerja	\N	2	0	4	1	\N	2024-04-02 21:20:06	2	0
8d0a63d3-7958-4e53-bd43-9eb90fae2165	49f95ca3-7345-44d7-adbb-bebf53ddcdec	f7e75882-2999-4371-8340-d19b6e7ea03f	Etiologi	\N	3	0	6	1	\N	2024-04-02 21:19:12	2	0
b4451b12-ec23-4440-8733-ca145fb3afa7	49f95ca3-7345-44d7-adbb-bebf53ddcdec	83e66970-ebab-4785-b008-c3a585de0847	RB	\N	0	0	32	1	\N	2024-04-02 21:20:06	0	3
9613add5-88d4-46db-9517-d1f8cfd5c14e	49f95ca3-7345-44d7-adbb-bebf53ddcdec	8ed14f4b-0fce-4f34-bbc0-0bdefd299dfe	Menentukan rujukan ke departemen lain untuk\nperawatan pre-ortodonti	\N	2	0	4	1	\N	2024-04-02 21:19:16	2	0
bb442089-fd84-46ed-b0dd-ef1c432f7b05	49f95ca3-7345-44d7-adbb-bebf53ddcdec	81872a92-496a-403c-94a3-92a21c7fa04f	AKTIVITAS	\N	0	0	16	1	\N	2024-04-02 21:19:16	0	1
b43992de-9416-4950-8faa-552dde1dc264	49f95ca3-7345-44d7-adbb-bebf53ddcdec	1874c32e-f5ab-4e46-a12e-57dc77c9decb	Menentukan rencana pencarian ruang, koreksi\nmalposisi gigi individual, occlusal adjustment dan\nretensi	\N	4	0	8	1	\N	2024-04-02 21:19:25	2	0
9102ea26-385d-4c22-a8b5-cf5365b9a255	49f95ca3-7345-44d7-adbb-bebf53ddcdec	230a4ba3-3667-4e24-8035-17cf9669d2c7	Menentukan komponen aktif yang digunakan	\N	4	0	8	1	\N	2024-04-02 21:19:28	2	0
cd5fedf8-063d-4350-bb6a-ca59305764e8	49f95ca3-7345-44d7-adbb-bebf53ddcdec	64cce734-113a-4364-bf2c-135e4a6096d5	Menentukan komponen aktif yang digunakan	\N	2	0	4	1	\N	2024-04-02 21:19:32	2	0
89be23fa-22b9-4f95-a134-b9b95063d26b	49f95ca3-7345-44d7-adbb-bebf53ddcdec	f30a9064-6d5b-43ac-9f4b-e038872934ba	Menentukan cengkeram retensi yang digunakan	\N	2	0	4	1	\N	2024-04-02 21:19:35	2	0
de946163-4588-4e71-a89a-645a3b3c3857	49f95ca3-7345-44d7-adbb-bebf53ddcdec	ec9de5bf-e7ed-464b-9690-7dcb093e1d59	Menentukan desain basis akrilik	\N	2	0	4	1	\N	2024-04-02 21:19:39	2	0
a8a8f890-061f-4811-8fbf-e12f78010fa9	49f95ca3-7345-44d7-adbb-bebf53ddcdec	cc4efdc7-85c0-4948-9d5a-a0ce9a04ee51	Menggambar desain alat lepasan di model kerja	\N	2	0	4	1	\N	2024-04-02 21:19:46	2	0
1b32c21c-0998-4dff-8ed7-dc1f86998ac8	49f95ca3-7345-44d7-adbb-bebf53ddcdec	abc44806-8529-48da-9f91-a1238efb83cc	RA	\N	0	0	32	1	\N	2024-04-02 21:19:46	0	2
10274d6a-851f-4670-8095-fa97374aa9c7	49f95ca3-7345-44d7-adbb-bebf53ddcdec	c83671ee-1072-435f-826a-47c22d8070cd	Menentukan rencana pencarian ruang, koreksi\nmalposisi gigi individual, occlusal adjustment dan\nretensi	\N	4	0	8	1	\N	2024-04-02 21:19:50	2	0
7a77c069-0697-4d27-aff8-f7b95b838304	49f95ca3-7345-44d7-adbb-bebf53ddcdec	7ba2e647-17e0-407c-ba07-f6285089b8d4	Menentukan komponen aktif yang digunakan	\N	4	0	8	1	\N	2024-04-02 21:19:53	2	0
95d9b637-270f-495a-8aa9-65a31c57850e	49f95ca3-7345-44d7-adbb-bebf53ddcdec	5d986557-5687-47ca-b197-9236ee242ae3	Menentukan komponen aktif yang digunakan	\N	2	0	4	1	\N	2024-04-02 21:19:57	2	0
0cecc8a5-e0bd-482a-a9f5-096dae9ea71d	49f95ca3-7345-44d7-adbb-bebf53ddcdec	887adda2-e502-491b-8274-11446b02228a	Menentukan cengkeram retensi yang digunakan	\N	2	0	4	1	\N	2024-04-02 21:20:00	2	0
4e6d4679-2607-4295-8e0a-622a4dc2d160	3b552933-8c5a-48ef-96e5-26fcc800697e	88d1a97a-5a63-4ad1-94c2-2edac74a7236	Menginsersikan alat ortodontik lepasan di depan instruktur\na. Rahang atas	\N	2	0	4	1	\N	2024-04-02 21:20:53	2	0
47ed4e4e-de46-4471-b596-92c175382dcf	49f95ca3-7345-44d7-adbb-bebf53ddcdec	239a3c5f-24e1-4d5e-8d5f-3a63eb272ea7	Menentukan desain basis akrilik	\N	2	0	4	1	\N	2024-04-02 21:20:03	2	0
6e771975-f383-4a31-b8bc-566ef1647419	3b552933-8c5a-48ef-96e5-26fcc800697e	bf1843e6-ad09-499e-8cd4-8c4ad52a8de1	Menjelaskan kepada pasien mengenai tindakan yang akan\ndilakukan	\N	2	0	4	1	\N	2024-04-02 21:20:43	2	0
e132cf93-088d-4d7c-8c01-1972fbc2cae7	3b552933-8c5a-48ef-96e5-26fcc800697e	82498fde-8f38-4f50-9c1b-6d5f13c194f1	Mempersiapkan alat diagnostic standard, rekam medik, dan\nmodel	\N	1	0	1	1	\N	2024-04-02 21:20:31	1	0
4d064a53-8943-48a6-9ecb-0f81e0f81a24	b65819bc-65b0-44fc-895d-9bf575416246	29435dc8-4f2b-4450-bbce-fe38ed48924d	Mempersiapkan alat diagnostik standard, rekam medik, dan\nmodel, alat aktivasi	\N	1	0	1	1	\N	2024-04-02 21:21:37	1	0
978dad14-8040-4d70-a695-d46f9256bf83	3b552933-8c5a-48ef-96e5-26fcc800697e	8f49e129-5247-476f-97b3-edeffe1da8ed	Mempersiapkan pasien di dental unit	\N	1	0	1	1	\N	2024-04-02 21:20:35	1	0
96e72200-42c9-4518-9dc2-57875c4302d0	3b552933-8c5a-48ef-96e5-26fcc800697e	0d8e9db3-526f-4e9b-9dae-bcbb1bc500e5	Menginsersikan alat ortodontik lepasan di depan instruktur\na. Rahang bawah	\N	2	0	2	1	\N	2024-04-02 21:20:57	1	0
ff243c29-7636-4d9d-a41a-1a174c8bed4b	3b552933-8c5a-48ef-96e5-26fcc800697e	5b0ef975-708f-481e-afec-281ecbb0fd7b	Menggunakan sarung tangan dan masker	\N	1	0	1	1	\N	2024-04-02 21:20:39	1	0
0865a04b-b06c-41d9-8f9a-7f632aac33d5	3b552933-8c5a-48ef-96e5-26fcc800697e	8da13bde-95bf-48fc-9f2a-006bcb35abda	Menunjukkan alat ortodontik lepasan yang siap diinsersi\nkepada instruktur	\N	1	0	1	1	\N	2024-04-02 21:20:47	1	0
29b4436e-92ec-4dd3-9774-a308d156b42c	3b552933-8c5a-48ef-96e5-26fcc800697e	19b7fef4-0216-46a7-9858-2cf9d720d027	Ketepatan dan menyesuaikan posisi letak komponen aktif,\npasif, retentif di dalam mulut\nb. Rahang bawah	\N	10	0	20	1	\N	2024-04-02 21:21:05	2	0
4fc94d09-57d1-4bf2-a618-0b673accca83	3b552933-8c5a-48ef-96e5-26fcc800697e	c90f40cd-1ad5-4882-86cd-26cb88cb8d4f	Menjelaskan dan menjawab pertanyaan yang diberikan\ninstruktur tentang hal yang berhubungan dengan insersi	\N	4	0	8	1	\N	2024-04-02 21:20:51	2	0
96750bae-3f14-4bf3-bf47-ebc52a32ea2c	3b552933-8c5a-48ef-96e5-26fcc800697e	625bba16-ca81-40f6-a333-824995d152f4	Sikap terhadap pasien selama perawatan berlangsung	\N	2	0	4	1	\N	2024-04-02 21:21:14	2	0
011cf773-918d-41ed-a3fe-300c498cd79a	b65819bc-65b0-44fc-895d-9bf575416246	17e05e42-5f97-44d9-a061-f8ee58eb75e3	Menggunakan sarung tangan dan masker	\N	1	0	1	1	\N	2024-04-02 21:21:44	1	0
a9c1778f-1c39-495c-a9d7-4e2f673e8cb2	3b552933-8c5a-48ef-96e5-26fcc800697e	052b1111-1ccd-4cb3-8d2f-c0caf63d4e65	Ketepatan dan menyesuaikan posisi letak komponen aktif,\npasif, retentif di dalam mulut\na. Rahang atas	\N	10	0	20	1	\N	2024-04-02 21:21:00	2	0
14492ced-b407-46fa-8f46-e7d69056c8a5	3b552933-8c5a-48ef-96e5-26fcc800697e	9733c6f0-bb87-4f7f-9683-62d12882b802	Ketepatan dan menyesuaikan posisi letak komponen aktif,\npasif, retentif di dalam mulut\nb. Rahang bawah	\N	10	0	10	1	\N	2024-04-02 21:21:08	1	0
2bed13a4-1d66-4ee0-9650-54c2bd251d05	b65819bc-65b0-44fc-895d-9bf575416246	edf45011-9872-42ba-ae33-25c5e4915a8c	Mempersiapkan pasien di dental unit	\N	1	0	1	1	\N	2024-04-02 21:21:40	1	0
9cbd94f2-8af3-4681-b9cf-24807a69c329	3b552933-8c5a-48ef-96e5-26fcc800697e	306ba922-c37e-4821-9b91-e8a830f5cf2f	Menjelaskan dan memberi instruksi kepada pasien\nmengenai alat yang telah dipakai (cara memasang dan\nmelepas, cara perawatan, dll)	\N	2	0	4	1	\N	2024-04-02 21:21:11	2	0
01c44cf9-ac1f-4256-8368-8773416a5b9d	3b552933-8c5a-48ef-96e5-26fcc800697e	50a6aad7-30c7-4952-b01d-dfaeeca8a8b7	Sikap terhadap instruktur selama\nperawatan berlangsung	\N	2	0	4	1	\N	2024-04-02 21:21:17	2	0
e264be4a-a83e-4795-9d63-719034059fb9	3b552933-8c5a-48ef-96e5-26fcc800697e	6a594806-8b9e-4be1-ac40-fd8608ef7e96	Tahapan	\N	0	0	84	1	\N	2024-04-02 21:21:17	0	1
e78255d9-c6b7-4f06-92be-f540dc0bb3f3	b65819bc-65b0-44fc-895d-9bf575416246	e62d524a-c821-47c7-8894-2907feea044b	Menjelaskan kepada pasien mengenai tindakan yang\nakan dilakukan	\N	2	0	4	1	\N	2024-04-02 21:21:48	2	0
c69d0b48-6da9-4f2a-a6d2-2fe4aa23d1b6	b65819bc-65b0-44fc-895d-9bf575416246	1b7645e5-739e-4d6e-9a98-27e9dbe6d6d6	Aktivitas	\N	0	0	73	1	\N	2024-04-02 21:22:30	0	1
0b9922a3-ac74-43fe-b590-ed396dc3a714	b65819bc-65b0-44fc-895d-9bf575416246	dde1956c-d5d4-4481-92af-b5ec49c28ebf	Menunjukkan pasien kepada instruktur sebelum alat\nortodontik lepasan diaktivasi (alat terpasang pada pasien)	\N	1	0	0	1	\N	2024-04-02 21:21:51	0	0
2b4756ff-cd16-4c74-b350-d306accd31f1	b65819bc-65b0-44fc-895d-9bf575416246	284da12b-3d3f-4740-8d1d-0f3e9c002032	Melakukan aktivasi komponen aktif di depan instruktur\nb. Rahang bawah	\N	3	0	6	1	\N	2024-04-02 21:21:55	2	0
9bfb81a2-5d27-439c-85d2-c703f2b6c968	b65819bc-65b0-44fc-895d-9bf575416246	18058000-459e-49f6-abc3-03fee8b14c6e	Menjelaskan dan menjawab pertanyaan yang diberikan\ninstruktur tentang hal yang berhubungan dengan cara\naktivasi dan pergerakan gigi	\N	5	0	10	1	\N	2024-04-02 21:21:59	2	0
a2a6849b-9332-4e10-a685-e9a308acada2	b65819bc-65b0-44fc-895d-9bf575416246	d8de084a-1511-4285-9a7f-16fe85cfc78c	Melakukan aktivasi komponen aktif di depan instruktur\na. Rahang atas	\N	3	0	6	1	\N	2024-04-02 21:22:02	2	0
226f0449-227c-43f6-8435-5e52175a0c14	b65819bc-65b0-44fc-895d-9bf575416246	df53544a-eb71-4cfa-bdba-4196f55f71b9	Menginsersikan alat yang telah diaktivasi di depan\ninstruktur\na. Rahang atas	\N	3	0	6	1	\N	2024-04-02 21:22:04	2	0
39b71941-eadd-4b47-991a-a5d3fc77e8a7	b65819bc-65b0-44fc-895d-9bf575416246	79e2796e-0db7-4a02-a6cd-e957beb12a44	Menginsersikan alat yang telah diaktivasi di depan\ninstruktur\nb. Rahang bawah	\N	3	0	6	1	\N	2024-04-02 21:22:09	2	0
17ba5951-e31d-48e9-b28e-37c7447a3d37	b65819bc-65b0-44fc-895d-9bf575416246	cea38bbc-5e51-4e5f-b80f-9184a7db7d52	Ketepatan dan penyesuaian letak komponen aktif, pasif,\nretentif di dalam mulut\na. Rahang atas	\N	6	0	12	1	\N	2024-04-02 21:22:13	2	0
37d8b571-0e43-45e2-a99f-a8d32a930333	b65819bc-65b0-44fc-895d-9bf575416246	17816e9c-1a93-44c2-8680-893ea55409e0	Ketepatan dan penyesuaian letak komponen aktif, pasif,\nretentif di dalam mulut\nb. Rahang bawah	\N	6	0	12	1	\N	2024-04-02 21:22:16	2	0
65653fa4-3e0f-486a-960c-9bd4c6126e4c	b65819bc-65b0-44fc-895d-9bf575416246	ea9d207c-adb6-468e-8238-8011f0b8272a	Menjelaskan dan memberi instruksi kepada pasien\nmengenai alat yang telah dipakai (cara memasang dan\nmelepas, perawatan, cara aktivasi jika memakai skrup\nexpansi, dll)	\N	3	0	6	1	\N	2024-04-02 21:22:19	2	0
834abbdb-d273-4bdb-94ef-65ad160524ee	b65819bc-65b0-44fc-895d-9bf575416246	345514da-9d65-44aa-a83c-c8542f6ce89b	Sikap terhadap pasien selama perawatan berlangsung	\N	1	0	1	1	\N	2024-04-02 21:22:26	1	0
4efb8883-324a-4ebc-b406-e3527e28d7a3	b65819bc-65b0-44fc-895d-9bf575416246	6765d4a7-1775-41df-a8a8-db6f7de6869b	Sikap terhadap instruktur selama perawatan berlangsung	\N	1	0	1	1	\N	2024-04-02 21:22:30	1	0
cd150d3e-275c-4baf-87c0-575182f58886	7e6b4293-adc6-400c-9101-d45ea91f2b5a	807a64f8-626b-46be-b20d-955ae5216a3d	Keserasian basis segi 7 dengan lengkung\ngigi	\N	10	0	10	1	\N	2024-04-02 21:23:35	1	0
dc8f50bd-4155-4845-b332-ecfbbc246277	5bc1f793-31dc-4f21-a46a-cfab00cec084	d2c20cea-8d6b-483a-9610-bf2689f811c8	Anamnesis (yang lama)	\N	2	0	4	1	\N	2024-04-02 21:24:11	2	0
ffa8ec80-7990-484b-b850-214e7c7093f8	7e6b4293-adc6-400c-9101-d45ea91f2b5a	2c92df75-2ce9-4025-88f5-7d997b1f5f10	Basis rahang atas dan rahang bawah\nsejajar	\N	12	0	24	1	\N	2024-04-02 21:23:39	2	0
f4f2e1fa-7596-4306-b16f-b2254ae61c3d	5bc1f793-31dc-4f21-a46a-cfab00cec084	dc7ef603-04b6-4108-999b-d41a1abb3651	Penulisan	\N	4	0	8	1	\N	2024-04-02 21:24:42	2	0
31d1da2d-4b80-480a-8fd5-d976d09edbc6	7e6b4293-adc6-400c-9101-d45ea91f2b5a	8817183e-125a-447e-bc70-a528534252f8	Dapat berdiri rapat pada setiap sisi	\N	10	0	20	1	\N	2024-04-02 21:23:42	2	0
6e12b757-15f4-43a2-8794-0aeea95a0fa9	5bc1f793-31dc-4f21-a46a-cfab00cec084	abc942ca-68bd-4a2e-a4b0-053a863256d7	Pemeriksaan EO dan IO (lama)	\N	2	0	4	1	\N	2024-04-02 21:24:15	2	0
f599aa86-805d-4414-b0b5-6797befcdef9	7e6b4293-adc6-400c-9101-d45ea91f2b5a	07a92aa7-a9eb-4437-b37e-4abd33e3b2d3	Kehalusan model studi	\N	8	0	16	1	\N	2024-04-02 21:23:45	2	0
7448ee0f-8bb6-42ee-bf76-3c1292731415	7e6b4293-adc6-400c-9101-d45ea91f2b5a	eb201b29-d6d6-403f-b03b-d0ab871fb597	Deskripsi	\N	0	0	70	1	\N	2024-04-02 21:23:45	0	1
f60d2637-136e-459d-acbd-5a2e9778a49d	5bc1f793-31dc-4f21-a46a-cfab00cec084	40be6b60-40d8-4969-8c0a-fb302c0debc1	Analisis model	\N	4	0	8	1	\N	2024-04-02 21:24:18	2	0
2ba62064-ae62-42fa-a206-f4e9e4729c03	5bc1f793-31dc-4f21-a46a-cfab00cec084	49b1415c-7965-48e1-81f3-898c13251610	Foto pasien extra dan intra oral (lama dan baru)	\N	4	0	8	1	\N	2024-04-02 21:24:22	2	0
ca3c4a01-58b4-4a7a-b275-fe40c92210d6	5bc1f793-31dc-4f21-a46a-cfab00cec084	ec44f7e4-9462-4bcc-8788-51e4fe622652	Deskripsi	\N	0	0	80	1	\N	2024-04-02 21:24:49	0	1
6020c68f-9c03-4175-8999-472b524a17dc	5bc1f793-31dc-4f21-a46a-cfab00cec084	ee509a0f-33b1-46cc-87c4-a7199d856ca4	Diagnosis (lama)	\N	2	0	4	1	\N	2024-04-02 21:24:25	2	0
76732401-e23a-4d62-80d7-c74104080458	5bc1f793-31dc-4f21-a46a-cfab00cec084	767624d5-14df-4786-b875-27516c4bf26c	Rencana perawatan (lama)	\N	2	0	4	1	\N	2024-04-02 21:24:28	2	0
255338c9-a833-4476-8048-374aeca0a998	5bc1f793-31dc-4f21-a46a-cfab00cec084	fe91bf22-ebc4-4fbd-a280-431ce2555039	Hasil perawatan	\N	4	0	8	1	\N	2024-04-02 21:24:31	2	0
626665ec-0d0e-478d-ab58-bccabcb1504e	5bc1f793-31dc-4f21-a46a-cfab00cec084	798ff61d-b04b-41be-b27f-6e598248a059	Kemampuan menjawab dan diskusi	\N	5	0	10	1	\N	2024-04-02 21:24:35	2	0
281a06b3-1da0-4ee9-9d51-5e589be27752	5bc1f793-31dc-4f21-a46a-cfab00cec084	92fe64c3-9c68-4f94-8963-67cc52dcbd39	Presentasi	\N	4	0	8	1	\N	2024-04-02 21:24:37	2	0
af2c7f58-a21d-45f6-890a-1f0665a05191	5bc1f793-31dc-4f21-a46a-cfab00cec084	6e177f82-1ffd-4010-a61a-a93349984fa6	Model studi (lama dan baru)	\N	4	0	8	1	\N	2024-04-02 21:24:46	2	0
072e59d6-3af2-4f50-937a-5b12da20dcda	5bc1f793-31dc-4f21-a46a-cfab00cec084	208351e1-6fbe-462f-98b2-28b2634b7fec	Sikap	\N	3	0	6	1	\N	2024-04-02 21:24:49	2	0
dc438655-5f32-4544-8dc5-5ae849266903	765b403c-8c79-473c-a3d3-2acc337e6b9b	81872a92-496a-403c-94a3-92a21c7fa04f	AKTIVITAS	\N	0	0	0	1	\N	\N	0	1
03162cec-47b6-4a91-96f7-603cddcc6870	765b403c-8c79-473c-a3d3-2acc337e6b9b	0e7e3f96-8b2e-4a2b-94df-7e590f492a25	Diagnosis	\N	3	0	0	1	\N	\N	0	0
e4e1ac11-7159-4ad5-b3f3-f31e7b3374b1	765b403c-8c79-473c-a3d3-2acc337e6b9b	f7e75882-2999-4371-8340-d19b6e7ea03f	Etiologi	\N	3	0	0	1	\N	\N	0	0
743e7c32-39f2-4c2c-9dce-d3fd922ffcf5	765b403c-8c79-473c-a3d3-2acc337e6b9b	8ed14f4b-0fce-4f34-bbc0-0bdefd299dfe	Menentukan rujukan ke departemen lain untuk\nperawatan pre-ortodonti	\N	2	0	0	1	\N	\N	0	0
fc9e668b-a255-470f-9b03-a2ba3c119027	765b403c-8c79-473c-a3d3-2acc337e6b9b	abc44806-8529-48da-9f91-a1238efb83cc	RA	\N	0	0	0	1	\N	\N	0	2
1e2b5395-93b9-4f1c-be57-676305a2d613	765b403c-8c79-473c-a3d3-2acc337e6b9b	1874c32e-f5ab-4e46-a12e-57dc77c9decb	Menentukan rencana pencarian ruang, koreksi\nmalposisi gigi individual, occlusal adjustment dan\nretensi	\N	4	0	0	1	\N	\N	0	0
960749a1-74ad-4cfa-85aa-8322bb4a0bbe	765b403c-8c79-473c-a3d3-2acc337e6b9b	230a4ba3-3667-4e24-8035-17cf9669d2c7	Menentukan komponen aktif yang digunakan	\N	4	0	0	1	\N	\N	0	0
91749263-8e57-4b77-a702-0e5690f86a3e	765b403c-8c79-473c-a3d3-2acc337e6b9b	64cce734-113a-4364-bf2c-135e4a6096d5	Menentukan komponen aktif yang digunakan	\N	2	0	0	1	\N	\N	0	0
4d8953ae-f189-41f2-b7ac-ce2b248f6901	765b403c-8c79-473c-a3d3-2acc337e6b9b	f30a9064-6d5b-43ac-9f4b-e038872934ba	Menentukan cengkeram retensi yang digunakan	\N	2	0	0	1	\N	\N	0	0
3c200418-5f76-466f-8ceb-62fcb2a9c53d	765b403c-8c79-473c-a3d3-2acc337e6b9b	ec9de5bf-e7ed-464b-9690-7dcb093e1d59	Menentukan desain basis akrilik	\N	2	0	0	1	\N	\N	0	0
855ac356-82e3-41c1-80f9-b4f4d18087c0	765b403c-8c79-473c-a3d3-2acc337e6b9b	cc4efdc7-85c0-4948-9d5a-a0ce9a04ee51	Menggambar desain alat lepasan di model kerja	\N	2	0	0	1	\N	\N	0	0
f1120e89-c4b9-4969-92e9-bb659040f78c	765b403c-8c79-473c-a3d3-2acc337e6b9b	83e66970-ebab-4785-b008-c3a585de0847	RB	\N	0	0	0	1	\N	\N	0	3
ac5a3183-4f29-4304-a935-86316168b87a	765b403c-8c79-473c-a3d3-2acc337e6b9b	c83671ee-1072-435f-826a-47c22d8070cd	Menentukan rencana pencarian ruang, koreksi\nmalposisi gigi individual, occlusal adjustment dan\nretensi	\N	4	0	0	1	\N	\N	0	0
f081a66d-d84e-4883-a0cb-b9497accfaad	765b403c-8c79-473c-a3d3-2acc337e6b9b	7ba2e647-17e0-407c-ba07-f6285089b8d4	Menentukan komponen aktif yang digunakan	\N	4	0	0	1	\N	\N	0	0
639fa80a-6f19-4739-80e4-554e963f1f46	765b403c-8c79-473c-a3d3-2acc337e6b9b	5d986557-5687-47ca-b197-9236ee242ae3	Menentukan komponen aktif yang digunakan	\N	2	0	0	1	\N	\N	0	0
876decb9-6f23-4f87-abd4-eb28e0ec3d72	765b403c-8c79-473c-a3d3-2acc337e6b9b	887adda2-e502-491b-8274-11446b02228a	Menentukan cengkeram retensi yang digunakan	\N	2	0	0	1	\N	\N	0	0
b9afefea-3653-4041-aadc-a4b23a07f350	765b403c-8c79-473c-a3d3-2acc337e6b9b	239a3c5f-24e1-4d5e-8d5f-3a63eb272ea7	Menentukan desain basis akrilik	\N	2	0	0	1	\N	\N	0	0
693c4de1-18e7-4c68-bd60-483ea8d06f50	765b403c-8c79-473c-a3d3-2acc337e6b9b	b2c062be-f857-4dc7-b428-b60e4bebdb7f	Menggambar desain alat lepasan di model kerja	\N	2	0	0	1	\N	\N	0	0
251b12ff-5be1-47fc-b2b6-67f7df3bb120	7851db96-24fc-4f7f-ab39-8314ffb40e2f	2383e153-b8b8-4d92-9630-4311f73296cb	Indikasi dan Pengisian Status	\N	0	0	0	1	\N	\N	0	1
4a2cff50-a0ab-4732-8317-e41addd1758b	7851db96-24fc-4f7f-ab39-8314ffb40e2f	da054ee2-ed91-4aa8-9b10-473441593093	Data pasien	\N	1	0	0	1	\N	\N	0	0
c1f53642-2bce-4c2e-913f-019b99b95028	6f46dad7-229b-44d4-a6c1-6a22d7034f61	7644b9f2-1729-40eb-a6c5-abe2545a4555	SIKAP	\N	0	0	0	1	\N	\N	0	2
1d28656f-359b-4703-8b96-fc14ae71c610	6f46dad7-229b-44d4-a6c1-6a22d7034f61	d3bbda49-4696-419d-a770-9e3e9e1bf01d	Inisiatif	\N	0	0	0	1	\N	\N	0	0
4f54582b-d6d5-45ac-8061-4dcd8328e7e3	6f46dad7-229b-44d4-a6c1-6a22d7034f61	80a50b4b-28b6-4c24-b1dd-38d04e446437	Disiplin	\N	0	0	0	1	\N	\N	0	0
cbe3e23b-e103-477f-8f70-37b917dda0a2	6f46dad7-229b-44d4-a6c1-6a22d7034f61	823d56f5-8d50-4ce0-98e1-a6c3eedc143a	Kejujuran	\N	0	0	0	1	\N	\N	0	0
d3c70826-b89c-4c07-9f78-39a6c87386bf	6f46dad7-229b-44d4-a6c1-6a22d7034f61	9e32d68a-0eb2-48c1-bc52-4a39d4f0d018	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
29ea9727-a175-4ae8-829a-01cff8910199	6f46dad7-229b-44d4-a6c1-6a22d7034f61	ed11558f-8782-44bc-86df-68eced45d5e7	Kerjasama	\N	0	0	0	1	\N	\N	0	0
4103ed16-eab9-4383-a47c-e7aea34807dc	6f46dad7-229b-44d4-a6c1-6a22d7034f61	95e9b0c0-f682-470b-95fe-69472cd7a1a9	Santun terhadap pasien	\N	0	0	0	1	\N	\N	0	0
4ac27ef6-810b-4a30-bce9-851e4c82889a	6f46dad7-229b-44d4-a6c1-6a22d7034f61	828a05e8-09ca-404e-ad19-37ea6cf19295	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
67dce2c4-afca-45da-b1c8-d362b9f02eb6	6f46dad7-229b-44d4-a6c1-6a22d7034f61	650d44b1-6c10-4a94-abf0-21702d538d39	Instruksi Pasien	\N	10	0	10	1	\N	2024-04-04 09:24:59	1	0
6f444c53-dc35-4b1d-8477-a373de60e254	f4d747ef-fae8-460b-a846-a7825a226ba2	1bed3bf5-e364-4345-8aba-376231eaa3a0	Informed Consent	\N	5	0	10	1	\N	2024-04-04 09:46:26	2	0
2dd24dac-1b86-4fc6-8e0e-6eb7e828c08c	6f46dad7-229b-44d4-a6c1-6a22d7034f61	e4179566-439c-4d6e-b7a2-d1a32228978e	Informed Consent	\N	5	0	10	1	\N	2024-04-04 09:24:31	2	0
62ed3c5d-fee2-49b2-b759-194d8e62691a	6f46dad7-229b-44d4-a6c1-6a22d7034f61	31d76d93-460c-4c22-8dc9-8ddac3055bd5	Exposure	\N	10	0	20	1	\N	2024-04-04 09:25:03	2	0
e82ec023-78f5-42e1-ae47-6f463db4e474	6f46dad7-229b-44d4-a6c1-6a22d7034f61	89382123-38f6-4e90-9526-30c7973bf572	Proteksi Radiasi	\N	5	0	10	1	\N	2024-04-04 09:24:42	2	0
6189056a-2f9f-4473-b773-7ec917e9cb51	6f46dad7-229b-44d4-a6c1-6a22d7034f61	519f2d87-ede2-47fa-98f2-defab532bff3	PEKERJAAN KLINIK	\N	0	0	80	1	\N	2024-04-04 09:25:03	0	1
88a0f8c7-1bec-425c-912c-0f4dd98f67af	6f46dad7-229b-44d4-a6c1-6a22d7034f61	77ebd490-e367-4058-be7f-09eac021c473	Posisi Pasien	\N	5	0	10	1	\N	2024-04-04 09:24:46	2	0
915044dc-3e8d-408d-9d62-ea7cd98f6612	6f46dad7-229b-44d4-a6c1-6a22d7034f61	ff6078d5-3b54-4bbd-a00d-cc66d3d1e259	Posisi Film	\N	5	0	10	1	\N	2024-04-04 09:24:51	2	0
ff118123-ef72-4362-ac12-6b764a8a016d	f4d747ef-fae8-460b-a846-a7825a226ba2	9a35780a-1033-4fdd-aaa8-8580a5281882	Posisi Pasien	\N	5	0	10	1	\N	2024-04-04 09:46:33	2	0
64ba4c33-ddd6-414b-b888-5498cc397b97	6f46dad7-229b-44d4-a6c1-6a22d7034f61	b5280e46-b162-4b9e-bfd0-2f7ab634e077	Posisi Tabung Xray	\N	5	0	10	1	\N	2024-04-04 09:24:55	2	0
6a8cf853-f0c2-47aa-a66a-985e00c5edee	f4d747ef-fae8-460b-a846-a7825a226ba2	65c55213-9613-485b-8921-f4487598bcc2	Proteksi Radiasi	\N	5	0	10	1	\N	2024-04-04 09:46:30	2	0
0b9e20d1-4de5-447d-b00a-89b8e6a82001	f4d747ef-fae8-460b-a846-a7825a226ba2	04f80df0-b91b-4e30-a084-e2419552e8e7	SIKAP	\N	0	0	0	1	\N	\N	0	2
7ea75216-d1f1-4c92-8d8b-7258e4ca55f5	f4d747ef-fae8-460b-a846-a7825a226ba2	2ef434b4-1489-4feb-9403-6372580cef3b	Inisiatif	\N	0	0	0	1	\N	\N	0	0
d97c56b3-78b9-4393-af45-702736a2b95b	f4d747ef-fae8-460b-a846-a7825a226ba2	8c97c0b9-ede4-4286-b683-b46222bdb97c	Disiplin	\N	0	0	0	1	\N	\N	0	0
8e27949d-7fc3-4ddb-9aed-a8788edc6361	f4d747ef-fae8-460b-a846-a7825a226ba2	d2e0746f-6048-406b-bcda-543906055701	Kejujuran	\N	0	0	0	1	\N	\N	0	0
d0609c4e-517c-42b5-a015-c3707d5a59ec	f4d747ef-fae8-460b-a846-a7825a226ba2	f6015203-a9cc-44ba-b39f-9fc31389dbf8	Posisi Film	\N	5	0	10	1	\N	2024-04-04 09:46:36	2	0
c7fd7833-4796-40e2-ab44-779837c47a28	f4d747ef-fae8-460b-a846-a7825a226ba2	a7794545-1f0c-4712-84c5-1cb9679a2487	Posisi Tabung Xray	\N	5	0	10	1	\N	2024-04-04 09:46:40	2	0
93c9fcc3-0a58-4234-9d7c-cb7dee31f786	f4d747ef-fae8-460b-a846-a7825a226ba2	2badf227-f96f-4e56-aa7e-fe503db46de9	Instruksi Pasien	\N	5	0	10	1	\N	2024-04-04 09:46:43	2	0
7f34e8dc-1994-4fb3-b43d-09cb1c04033d	f4d747ef-fae8-460b-a846-a7825a226ba2	89cb9879-b7e4-46b8-91e9-b7e72dd32114	Exposure	\N	5	0	10	1	\N	2024-04-04 09:46:46	2	0
f212a1ef-cb70-4027-93e6-c493d62f1ce7	f4d747ef-fae8-460b-a846-a7825a226ba2	567af7c7-13d4-4335-a190-dd62b4d3c7ea	Prosesing	\N	5	0	10	1	\N	2024-04-04 09:46:49	2	0
1c152fc4-a78c-4fcd-a6ca-e966b4bf30f8	f4d747ef-fae8-460b-a846-a7825a226ba2	512a4232-a0f9-4b42-931f-e63a3c4db4f9	PEKERJAAN KLINIK	\N	0	0	80	1	\N	2024-04-04 09:46:49	0	1
e27a3d76-2dc2-4c34-b98f-d8fa76766950	f4d747ef-fae8-460b-a846-a7825a226ba2	b6ffd467-4337-468d-b282-3628665408a4	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
b6afbba8-2435-4660-a331-0406e09f64e4	f4d747ef-fae8-460b-a846-a7825a226ba2	0ee7a1eb-1be0-4c40-9bd9-d3022e136c59	Kerjasama	\N	0	0	0	1	\N	\N	0	0
4d52f881-9acb-4031-a95c-cdfdefad3e18	f4d747ef-fae8-460b-a846-a7825a226ba2	c5e602b4-37b2-448b-970f-f7915d4b0a46	Santun terhadap pasien	\N	0	0	0	1	\N	\N	0	0
cf8f3d32-3917-4c73-bd5d-4ceb3cdd0a4a	f4d747ef-fae8-460b-a846-a7825a226ba2	019f7fb4-2ac7-4cc4-8fbc-86602cab53b2	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
ecfd467a-1350-45a8-b413-17ead113ef5a	f1235601-d6bc-4844-84a1-1e18988c2dbf	fbac69ca-23dc-454d-b77f-9777a32d7a5d	SIKAP	\N	0	0	0	1	\N	\N	0	2
c33f3c7b-0553-4a02-b18e-49f87ca14a06	f1235601-d6bc-4844-84a1-1e18988c2dbf	b5d94bd4-dcfc-4602-9297-c00847852dea	Inisiatif	\N	0	0	0	1	\N	\N	0	0
4dc6a83b-fa67-40ac-84f4-327da15ee96d	f1235601-d6bc-4844-84a1-1e18988c2dbf	518e948d-dd5a-42a7-9cd8-df35a6510b88	Disiplin	\N	0	0	0	1	\N	\N	0	0
e3f25e55-9fe7-4354-81b1-16df3862d46c	f1235601-d6bc-4844-84a1-1e18988c2dbf	f603ceea-42c3-49a7-a9ab-0ee3227a2e72	Kejujuran	\N	0	0	0	1	\N	\N	0	0
6cb75168-f250-4f31-8301-c59c33603ca9	f1235601-d6bc-4844-84a1-1e18988c2dbf	4009e0ce-7dc9-407e-be56-7292002c9f1f	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
772da94c-4266-4ad9-b8ef-2e129485f7a6	f1235601-d6bc-4844-84a1-1e18988c2dbf	24d7d73c-d5e9-4868-93b7-de9229b499a2	Kerjasama	\N	0	0	0	1	\N	\N	0	0
65415b84-a07c-4829-bb40-2da952c042d0	f1235601-d6bc-4844-84a1-1e18988c2dbf	8c4c52d4-baf1-43d2-a6cb-cd62259bc6e7	Santun terhadap pasien	\N	0	0	0	1	\N	\N	0	0
ba8fdf30-ba54-4526-b95d-80a01c90f43a	f1235601-d6bc-4844-84a1-1e18988c2dbf	e9e25456-79dc-47b5-8e6d-5615706020ab	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
417d6db3-5efe-4878-b8e7-e4708401bd65	f1235601-d6bc-4844-84a1-1e18988c2dbf	8520b176-2b33-459f-bf63-97a3e153e45d	Informed Consent	\N	5	0	10	1	\N	2024-04-04 09:47:21	2	0
e0a803f7-1c62-4dad-a1b1-b0aede53ee7f	c91514be-bbcd-4474-a54e-c5493943aa16	b1bde434-acb3-4d0e-b5ea-f22e0b0940ef	Menerima dan membaca rujukan pemeriksaan  radiograf periapikal, melakukan informed consent pada pasien dan  menulis  pada  buku  catatan  di  ruang Xray	\N	2	0	4	1	\N	2024-04-04 09:48:10	2	0
2bd7697f-fb0e-4666-b144-abb9ab665a4c	f1235601-d6bc-4844-84a1-1e18988c2dbf	7236b2ff-217d-4998-9ef3-41b144e453f4	Proteksi Radiasi	\N	5	0	10	1	\N	2024-04-04 09:47:25	2	0
69106707-fb12-4c62-8a67-1110d6b86598	c91514be-bbcd-4474-a54e-c5493943aa16	3be73c17-b7d0-40b8-a16f-a64591c5a9e5	Pasien diinstruksikan untuk memakai apron pelindung radiasi	\N	3	0	6	1	\N	2024-04-04 09:48:24	2	0
ea3eeb43-25b3-429a-b51d-c0505caff4c7	f1235601-d6bc-4844-84a1-1e18988c2dbf	326fef6b-1ae2-4248-89a4-991922cbb136	Posisi Pasien	\N	5	0	10	1	\N	2024-04-04 09:47:28	2	0
2c0d4adb-53ec-4515-8c75-9f99ba0363d6	c91514be-bbcd-4474-a54e-c5493943aa16	e9fe4b01-3356-4836-9b40-b6e2c1f4e246	Mempersiapkan alat xray intraoral, memilih lama eksposur pada panel kontrol dan film yang akan digunakan	\N	2	0	4	1	\N	2024-04-04 09:48:13	2	0
251b5a66-6832-4463-8ea3-c37fb76ef01f	f1235601-d6bc-4844-84a1-1e18988c2dbf	b9302baf-0246-4848-bc4c-16423150724b	Posisi Film	\N	5	0	10	1	\N	2024-04-04 09:47:31	2	0
e64163ab-e23c-4119-8991-4d6a38ffc7e8	c91514be-bbcd-4474-a54e-c5493943aa16	5fdf51ed-449d-4e5f-a62f-4f9ed89e7c26	Jari pasien diarahkan untuk me-fiksasi film	\N	2	0	4	1	\N	2024-04-04 09:48:34	2	0
70c92e36-7373-415f-b5e8-14b7846dc690	f1235601-d6bc-4844-84a1-1e18988c2dbf	169344ad-20af-4905-a2b5-7585fa61fb06	Posisi Tabung Xray	\N	5	0	10	1	\N	2024-04-04 09:47:37	2	0
8cfcf723-c6d0-4079-b90e-114f3c66867e	c91514be-bbcd-4474-a54e-c5493943aa16	8db2983a-640f-4476-bf2f-82fbecefe22a	Mempersilahkan  pasien  untuk  masuk  dan\nmenjelaskan kepada pasien prosedur pemeriksaan radiologis menggunakan teknik periapikal bisektris	\N	5	0	10	1	\N	2024-04-04 09:48:17	2	0
32ae46cc-521c-4dcc-ae14-da3aab8644e8	f1235601-d6bc-4844-84a1-1e18988c2dbf	cdcbb703-4912-4b17-9b7b-be748d7ae249	Instruksi Pasien	\N	5	0	10	1	\N	2024-04-04 09:47:40	2	0
8c7d9fdd-2456-4f13-99ac-8e1fbc2f8871	c91514be-bbcd-4474-a54e-c5493943aa16	89d5f270-9bf7-43ce-a136-ea66e9cf168e	PEKERJAAN KLINIK	\N	0	0	96	1	\N	2024-04-04 09:49:03	0	1
bb32698f-0a6a-4a6c-9e91-6066672558f5	f1235601-d6bc-4844-84a1-1e18988c2dbf	ec8f5218-ecf9-461f-bbeb-2df2dad9285d	Exposure	\N	5	0	10	1	\N	2024-04-04 09:47:43	2	0
44aa1572-3b84-430d-adce-f12577c19677	c91514be-bbcd-4474-a54e-c5493943aa16	f7f56eee-c3b2-4196-88fe-0b6ee19d17f4	Menggunakan Masker dan Sarung tangan	\N	2	0	4	1	\N	2024-04-04 09:48:21	2	0
897bb3a8-5af9-42a4-a771-651d2036a983	f1235601-d6bc-4844-84a1-1e18988c2dbf	0168ed48-f471-4cc5-a9e0-d51cb5737ac1	Prosesing	\N	5	0	10	1	\N	2024-04-04 09:47:46	2	0
698f05ce-1e48-4e84-9894-1035358e9230	f1235601-d6bc-4844-84a1-1e18988c2dbf	52c00875-ff5b-40fa-bf03-2c57d786c6ec	PEKERJAAN KLINIK	\N	0	0	80	1	\N	2024-04-04 09:47:46	0	1
e589becb-0f6e-4e99-a305-a4ca0a607083	c91514be-bbcd-4474-a54e-c5493943aa16	26fb5ed1-f586-4805-b431-c73e532b850e	Mengatur Tabung eksposi pada:\na. Sudut vertikal disesuaikan objek yang akan diperiksa\nb. Sudut Horizontal disesuaikan objek yang akan diperiksa	\N	10	0	20	1	\N	2024-04-04 09:48:37	2	0
8e2c9134-d0d3-4264-8261-f4239c30ef8f	c91514be-bbcd-4474-a54e-c5493943aa16	457aae28-a96e-4450-a471-10ff880dccc5	Mempersilahkan pasien duduk di alat xray\ndan memposisikan kepala pasien: \na. Kepala bersandar pada headrest \nb. Bidang sagital tegak lurus lantai\nc. Bidang oklusal sejajar dengan lantai	\N	10	0	20	1	\N	2024-04-04 09:48:27	2	0
254eca48-28b1-4d9e-a10c-f0fafbd72951	c91514be-bbcd-4474-a54e-c5493943aa16	43f89f49-b5ff-47c6-8b41-f6532256ad31	Menginstruksikan pasien untuk tidak bergerak   dan   dan   menjelaskan   operator akan melakukan eksposi	\N	1	0	1	1	\N	2024-04-04 09:48:51	1	0
d7a8c50a-14e9-4d1b-b4ab-171ab8296a5f	f1d81703-6390-4b29-b9d8-1fbaf6480c1b	fe5b0c0d-9b9b-4f9e-9035-9f2f9d7a21a0	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
8b3ab270-752a-4037-af1d-6232c3d4752c	c91514be-bbcd-4474-a54e-c5493943aa16	40aa31de-c592-40b9-a2f0-99b45f6d0b94	Meletakkan film   intraoral kedalam mulut pasien, posisi objek yang akan diperiksa berada di  tengah film. Dot  film  berada  di insisal/oklusal gigi.	\N	5	0	10	1	\N	2024-04-04 09:48:31	2	0
a1afcf45-e412-47aa-a8ec-f8d4bead2e7e	c91514be-bbcd-4474-a54e-c5493943aa16	ab29848c-1713-44d0-8ae6-8ff7a15a7d5d	Mengarahkan tabung eksposi sesuai dengan titik penetrasi objek.	\N	5	0	10	1	\N	2024-04-04 09:48:43	2	0
f7488ad0-5499-4906-a386-8451ddafa755	c91514be-bbcd-4474-a54e-c5493943aa16	cffbd13b-a92e-46f6-a65a-208136261a11	Memencet tombol eksposi	\N	1	0	1	1	\N	2024-04-04 09:48:55	1	0
40241488-26db-4b7e-92b6-66dbed82b331	c91514be-bbcd-4474-a54e-c5493943aa16	8f9a5f01-1723-4f02-952a-45ffffd2b050	Mengeluarkan  fim  dari  mulut  pasien  dan mempersilahkan   pasien   berdiri,   melepas apron pelindung radiasi.	\N	1	0	1	1	\N	2024-04-04 09:48:59	1	0
39b6ad35-c1c5-4bd2-a7e2-4cf520f260e2	c91514be-bbcd-4474-a54e-c5493943aa16	c36494b4-8f30-4b6a-8020-84a37b4b80ca	SIKAP	\N	0	0	0	1	\N	\N	0	2
44b1e5e4-b0a6-47cd-96ef-82a4b639d45d	c91514be-bbcd-4474-a54e-c5493943aa16	fe20ae99-30ce-4cea-a454-37359f16c3bd	Inisiatif	\N	0	0	0	1	\N	\N	0	0
aca710cf-b375-40c2-854f-b9da7874f3ed	c91514be-bbcd-4474-a54e-c5493943aa16	7eab875a-ad52-4ff2-971b-63e30724b03c	Disiplin	\N	0	0	0	1	\N	\N	0	0
a81f437e-116c-4da2-b668-a36af5c41170	c91514be-bbcd-4474-a54e-c5493943aa16	af754f5e-cdef-4660-bc34-2bc09e06bc26	Kejujuran	\N	0	0	0	1	\N	\N	0	0
f3ccbe32-8826-4b49-84d6-7d05a2434ba5	c91514be-bbcd-4474-a54e-c5493943aa16	6a89654c-909f-43e3-ab47-d39c30037418	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
6149c380-ead3-4e46-8064-4a7c595e68c3	c91514be-bbcd-4474-a54e-c5493943aa16	e63c6735-4cde-4093-98cd-0b2822c924ce	Kerjasama	\N	0	0	0	1	\N	\N	0	0
7bbce261-4e4f-4927-baec-02e4a83bc95d	c91514be-bbcd-4474-a54e-c5493943aa16	dc8f07b1-45cd-4977-8ce2-312f5455bf19	Santun terhadap Pasien	\N	0	0	0	1	\N	\N	0	0
0eb6c06c-04a2-4b21-a167-125504e9e85a	c91514be-bbcd-4474-a54e-c5493943aa16	a8e52691-7aa2-4ade-8323-e4e5495fb63b	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
7661168c-b703-462f-8fc6-ed84a0654477	c91514be-bbcd-4474-a54e-c5493943aa16	666c4222-69c1-421b-8200-a10290440162	Mempersilahkan  pasien  kembali  ke  ruang tunggu untuk menunggu hasil radiograf.	\N	1	0	1	1	\N	2024-04-04 09:49:03	1	0
bc91b1ca-b5a6-4eb0-9009-e1ac3d23edab	15ea3d80-7ebd-40b8-8c5d-1e534c1ec6c6	782aa962-1ddb-4442-9db2-fa43946848bd	SIKAP	\N	0	0	0	1	\N	\N	0	2
81ba4fc2-a190-4e4a-a6ca-0d7dba15d399	15ea3d80-7ebd-40b8-8c5d-1e534c1ec6c6	0209f583-008f-414b-bcf7-7a389dbf224d	Inisiatif	\N	0	0	0	1	\N	\N	0	0
5a18808d-e851-48cd-8b63-754da3b38c00	15ea3d80-7ebd-40b8-8c5d-1e534c1ec6c6	a889ca74-b784-43e1-90c0-5833b32898df	Disiplin	\N	0	0	0	1	\N	\N	0	0
d5ec4358-2eef-4eef-b23b-58fc4360d6fd	15ea3d80-7ebd-40b8-8c5d-1e534c1ec6c6	d70c5578-b960-4272-9e36-01bfc68586d5	Kejujuran	\N	0	0	0	1	\N	\N	0	0
d66af377-c7d9-4f35-9aa1-3fdc2aeb84dc	15ea3d80-7ebd-40b8-8c5d-1e534c1ec6c6	47a4695a-8eca-4d21-8ae5-dee4e708794d	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
a86e784f-fd36-46c4-a988-552ac1b03cda	15ea3d80-7ebd-40b8-8c5d-1e534c1ec6c6	a91e2a00-a885-49d4-8ca0-b442b3b10dfd	Kerjasama	\N	0	0	0	1	\N	\N	0	0
2cfa9e40-b413-405c-9188-0b0e4cb6647d	15ea3d80-7ebd-40b8-8c5d-1e534c1ec6c6	8a748853-439a-49be-8dd8-26745b5e3bdb	Santun terhadap Pasien	\N	0	0	0	1	\N	\N	0	0
32b27d45-7e83-4b3f-b062-cf67b5bdd6e6	15ea3d80-7ebd-40b8-8c5d-1e534c1ec6c6	4314ce0c-e122-44fe-807b-00c5bbdb196a	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
12119cbd-07ec-4d40-b3f7-8847083af804	8afc6ac5-dfde-453b-bf55-c225c5e8a1d2	1c95a8ad-f56e-4afd-aaa6-11f8ab73c58d	DD	\N	5	0	0	1	\N	\N	0	0
29174ad4-a227-4c8f-bede-80b5fb15dd83	8afc6ac5-dfde-453b-bf55-c225c5e8a1d2	e098aae3-ad03-4424-b3e2-82d47c59504e	SIKAP	\N	0	0	0	1	\N	\N	0	2
e7d822ec-c0de-40b0-b397-f7457c52f9b9	8afc6ac5-dfde-453b-bf55-c225c5e8a1d2	c6892221-3a8c-427b-a7dc-76d4c9576c50	Inisiatif	\N	0	0	0	1	\N	\N	0	0
f0459a9f-e095-4061-80e9-b230fcbd22e7	8afc6ac5-dfde-453b-bf55-c225c5e8a1d2	d4488ac8-5ad1-4dc9-9d4e-e530d5be0176	Disiplin	\N	0	0	0	1	\N	\N	0	0
b35e5202-d367-4cdf-8c45-742d689b3474	8afc6ac5-dfde-453b-bf55-c225c5e8a1d2	98e4091f-768a-4666-b1b1-8873ad519d51	Kejujuran	\N	0	0	0	1	\N	\N	0	0
77334446-eaa4-4a3a-9b08-9ff112c8a63e	8afc6ac5-dfde-453b-bf55-c225c5e8a1d2	e26cb3a0-ea51-447e-8bc0-e21e9e8938d4	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
1cc29b4f-002c-43c0-8770-3b6b055f7c57	8afc6ac5-dfde-453b-bf55-c225c5e8a1d2	0bfe6537-d840-4960-b452-bc8c9d91f801	Kerjasama	\N	0	0	0	1	\N	\N	0	0
0571f775-607c-4ae4-8f4c-2cc45aa3f3ab	8afc6ac5-dfde-453b-bf55-c225c5e8a1d2	3faef3fc-517a-4bf9-9c01-e824298d4cfc	Santun terhadap pasien	\N	0	0	0	1	\N	\N	0	0
23c6fe8c-5d82-4ea4-ac76-bb43ca204fc9	8afc6ac5-dfde-453b-bf55-c225c5e8a1d2	79d412d7-0b8d-44ed-a9d2-5763b684a0d8	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
d9a505d8-b585-4709-8b37-7066214666ae	8afc6ac5-dfde-453b-bf55-c225c5e8a1d2	14a3f7d0-bcf3-4884-b620-c8f8e72a7b42	Site : lokasi at regio	\N	5	0	10	1	\N	2024-04-04 09:51:51	2	0
6a646c45-2a99-4734-bf7b-3d861591ae1a	f1d81703-6390-4b29-b9d8-1fbaf6480c1b	55dbc8b0-787e-4e87-999d-22ad5f4bc2ea	Menilai kualitas radiograf :\n6.\tkontras radiograf : nilai kontras yang baik jika gambaran jaringan terlihat dengan jelas (radiopak dan radiolusen jelas)\n7.\tKetajaman (Sharpness) Radiograf : Ketajaman (sharpness) didefinisikan sebagai kemampuan dari suatu radiograf untuk menjelaskan tepi atau batas-batas dari objek yang tampak\n8.\tDetail Radiograf : Detail radiograf menjelaskan tentang bagian terkecil dari objek masih dapat tervisualisasi dengan baik pada radiograf (perbedaan tiap objek misal: dentin, email)\n9.\tDensitas suatu radiograf  :  keseluruhan derajat penghitaman pada sebuah film/reseptor yang telah diberikan paparan radiasi diukur sebagai densitas optik dari area suatu film. Densitas ini bergantung pada ketebalan objek, densitas objek, dan tingkat pemaparan sinar x.\n10.\tBrightness : keseimbangan antara warna terang dan gelap pada suatu gambaran radiografi.	\N	10	0	20	1	\N	2024-04-04 09:52:21	2	0
80f8dec4-14de-40a8-9ab6-8be8d971e078	8afc6ac5-dfde-453b-bf55-c225c5e8a1d2	94d4e79e-09b6-4188-80d5-65d3dfd25370	Associations : hub/efek terhadap struktur lain disekitarnya	\N	5	0	10	1	\N	2024-04-04 09:51:54	2	0
59c55194-fa51-4119-9aba-94e45866107f	8afc6ac5-dfde-453b-bf55-c225c5e8a1d2	a9d00a52-2a54-46af-b6a1-a33347e84bcc	Suspek Radiodiagnosis	\N	10	0	20	1	\N	2024-04-04 09:51:58	2	0
50e6cd3f-5435-4110-a07e-1a39d9681be4	8afc6ac5-dfde-453b-bf55-c225c5e8a1d2	3e66cba6-b744-46da-8baf-cb77bd677fa4	PEKERJAAN KLINIK	\N	0	0	40	1	\N	2024-04-04 09:51:58	0	1
8f9f8f55-17b4-4bb8-b9d9-8da810bf46d1	f1d81703-6390-4b29-b9d8-1fbaf6480c1b	1ca15f03-202e-4ec3-9587-9512377846f7	Interpretasi mahkota :\n1. Densitas: radioopak/radiolusen\n2. Lokasi: oklusal/proximal/cervikal\n3. Kedalaman: meliputi elemen gigi apa (sampai email/dentin/pulpa)	\N	2	0	4	1	\N	2024-04-04 09:52:26	2	0
b24c0938-0577-4774-ad34-473f36cebe8e	f1d81703-6390-4b29-b9d8-1fbaf6480c1b	178ede31-429f-4789-87c4-10cfe51433d1	PEKERJAAN KLINIK	\N	0	0	100	1	\N	2024-04-04 09:52:57	0	1
6fcf0731-b9c6-4db4-92f8-77e583d6856d	f1d81703-6390-4b29-b9d8-1fbaf6480c1b	5754d680-1cee-44e7-bbea-751ee3ea55d5	Interpretasi akar:\n1. Jumlah akar : tunggal(1)/2,3\n2. Bentuk akar : divergen/konvergen/Dilaserasi\n4.\tDensitas : radioopak/radiolusen	\N	2	0	4	1	\N	2024-04-04 09:52:29	2	0
e487232b-365a-4744-a509-5fe5001672bb	f1d81703-6390-4b29-b9d8-1fbaf6480c1b	17c07d88-7300-4719-9678-cb4ddea3a18b	Interpretasi ruang membran periodontal :\n1. DBN/menghilang/ melebar\n2. Lokasi : seluruh akar/ 1/3 apikal dll	\N	2	0	4	1	\N	2024-04-04 09:52:32	2	0
3f8cab92-d575-4261-908c-257308215e2a	f1d81703-6390-4b29-b9d8-1fbaf6480c1b	088b1b5a-d66e-48ac-ae06-3b98c8630f9f	Interpretasi laminadura :\n1. DBN/terputus/menghilang/menebal\n2. Lokasi : seluruh akar/ 1/3 apikal dll	\N	2	0	4	1	\N	2024-04-04 09:52:35	2	0
c5d9ed56-6201-4c97-96e7-1717cf3a32be	f1d81703-6390-4b29-b9d8-1fbaf6480c1b	ef9dc18d-a45f-4c0d-b8bd-016c669d78cf	Interpretasi puncak tulang alveolar :\n1.DBN(1-3mm)/mengalami penurunan\n2.Tipe penurunan (vertikal/horizontal)\n3.Berapa mm penurunan puncak tulang alveolar dari CEJ	\N	2	0	4	1	\N	2024-04-04 09:52:39	2	0
98d8f47f-7808-47a9-b022-ea12a96d3e22	f1d81703-6390-4b29-b9d8-1fbaf6480c1b	1eabb88a-3425-4a36-aa82-afa073814f40	Interpretasi furkasi : \n1. pelebaran membran\n2. Penurunan tulang alveor\n3 radiolusen/radioopak/DBN	\N	2	0	4	1	\N	2024-04-04 09:52:42	2	0
7ed3ff5f-7ecc-4036-b615-441a9125f7ab	f1d81703-6390-4b29-b9d8-1fbaf6480c1b	4f0af24c-a395-4bfd-92c5-e8dbe0f6dae3	SIKAP	\N	0	0	0	1	\N	\N	0	2
5197362e-2230-4f02-bd05-d1f7f0539ad2	f1d81703-6390-4b29-b9d8-1fbaf6480c1b	3fa4d321-b195-4312-a16f-a01f601447bd	Inisiatif	\N	0	0	0	1	\N	\N	0	0
b6145302-68ae-4c29-b6d7-4583457ca6bb	f1d81703-6390-4b29-b9d8-1fbaf6480c1b	17e76aac-9485-412a-9282-028a1ac90e9b	Disiplin	\N	0	0	0	1	\N	\N	0	0
5e8b98fd-b86b-46c4-9ea6-7d05767cbc9f	f1d81703-6390-4b29-b9d8-1fbaf6480c1b	d03fd532-2c6d-47ca-b1ff-1dde9ae6596d	Kejujuran	\N	0	0	0	1	\N	\N	0	0
f9b4e1e2-a971-403f-ad26-dfc575163ae1	f1d81703-6390-4b29-b9d8-1fbaf6480c1b	231cf889-791d-46b3-9b9b-7c05c31bef1d	Kerjasama	\N	0	0	0	1	\N	\N	0	0
e19ca7cb-0232-4795-9def-f38996b0bcc4	f1d81703-6390-4b29-b9d8-1fbaf6480c1b	25b6e277-b588-4df5-96f8-56f9a72ec27b	Santun terhadap pasien	\N	0	0	0	1	\N	\N	0	0
06a995cd-4637-4d3e-add8-44ded2aa4b68	f1d81703-6390-4b29-b9d8-1fbaf6480c1b	82ca3463-64fa-4439-adb9-bc2a21df6dd0	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
129620c3-3528-455b-a97b-a01261785994	f1d81703-6390-4b29-b9d8-1fbaf6480c1b	ad6ca5a2-8152-4c5a-b63d-79e2a2ee90b0	Interpretasi periapikal \n1. Site : lokasi at regio apa\n2. Size : ukuran x.y mm/ sebesar kacang polong dll\n3. Shape : bulat/oval/reguler/irreguler\n4. Symmetry\n5. Borders : batas jelas dan tegas/ jelas tidak tegas/ tidak jelas dan tidak tegas/ reguler/irreguler\n6. Contents :\nradiolusen/radioopak/mixed\n7. Associations : hub/efek terhadap struktur lain disekitarnya\n8. Jumlah : unilokuler/multilokuler	\N	10	0	20	1	\N	2024-04-04 09:52:45	2	0
1f31a5ee-3173-47a3-ab2f-54049bf6a42a	f1d81703-6390-4b29-b9d8-1fbaf6480c1b	6e182dd4-f341-4621-9e16-e5248702f9c7	Membuat Kesan :\nMenyebutkan kelainan pada setiap elemen.\n“Terdapat kelainan pada mahkota, akar...”	\N	3	0	6	1	\N	2024-04-04 09:52:49	2	0
92bda4e7-55f7-4aa3-b9e5-2596f787cb9f	f1d81703-6390-4b29-b9d8-1fbaf6480c1b	10de4d3a-bba0-47f5-ae35-e5fb819923a7	Menentukan suspect radiodiagnosis	\N	10	0	20	1	\N	2024-04-04 09:52:54	2	0
cf695b02-cb40-48da-86df-34bee2e83dce	f1d81703-6390-4b29-b9d8-1fbaf6480c1b	9fb2de18-6c2d-4ce7-b60f-40c478f1fef7	Menentukan differensial diagnosis	\N	5	0	10	1	\N	2024-04-04 09:52:57	2	0
21fef545-ee7e-4816-a43e-99cbdd30a081	271c46df-d1e1-440c-a3bd-5a865c088441	d86aad7c-9003-4d24-ab0b-32a754ad880c	SIKAP	\N	0	0	0	1	\N	\N	0	2
427f8816-7100-47a9-a778-8745734eb297	271c46df-d1e1-440c-a3bd-5a865c088441	db5bef52-9fd3-49bf-b805-35b5e8128a0a	Inisiatif	\N	0	0	0	1	\N	\N	0	0
a241b954-f06d-406b-8612-b00499601c60	271c46df-d1e1-440c-a3bd-5a865c088441	9ce7810c-dd59-42c5-9b4b-c8d084be483c	Disiplin	\N	0	0	0	1	\N	\N	0	0
f4ac4220-f985-4c66-9cb0-a3783a16cff8	271c46df-d1e1-440c-a3bd-5a865c088441	dcd6c8f5-e34a-46ce-8839-de1516ea16a2	Kejujuran	\N	0	0	0	1	\N	\N	0	0
3206e716-14b6-4755-9c7e-92240b34cf09	271c46df-d1e1-440c-a3bd-5a865c088441	f804e7c5-367e-4ad8-b9ee-28ee8e0a932b	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
9090bcc0-c7b8-4849-935b-b20c90ddcefe	271c46df-d1e1-440c-a3bd-5a865c088441	47a90071-4d37-49dc-b275-b5a0de2a9b87	Kerjasama	\N	0	0	0	1	\N	\N	0	0
640a2566-1bd6-4e30-87ab-abd677541504	271c46df-d1e1-440c-a3bd-5a865c088441	0825bb70-afd3-4d76-a91a-6f9fea72a665	Santun terhadap rekan	\N	0	0	0	1	\N	\N	0	0
13b81d4c-72e4-48a3-b5bc-3f94e75f06d0	271c46df-d1e1-440c-a3bd-5a865c088441	272709d1-add1-4d0e-a1e1-7afb5104fbf0	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
40765379-1000-4aac-9c90-b6b83a15f15e	271c46df-d1e1-440c-a3bd-5a865c088441	0d5962c7-e8c1-4cd9-a027-1cd9bf310377	Isi	\N	15	0	30	1	\N	2024-04-04 09:53:16	2	0
1b16ab96-67e2-40b7-8032-142e058606b0	271c46df-d1e1-440c-a3bd-5a865c088441	6e69afdb-02e4-49c5-a39d-599bf2c562dc	Presentasi: ppt, kejelasan suara, sistematis, semangat, gaya	\N	10	0	20	1	\N	2024-04-04 09:53:19	2	0
ed9254be-5fcc-41f8-bd7a-591009014884	271c46df-d1e1-440c-a3bd-5a865c088441	0877dfa9-e93e-499f-a437-c89e1146dc3b	Kemampuan menerangkan	\N	5	0	10	1	\N	2024-04-04 09:53:24	2	0
1eb78b47-57df-4a2e-ac25-aff94fc3d0f6	271c46df-d1e1-440c-a3bd-5a865c088441	bf801d5f-f2cc-48d4-bcae-ba58945de9f7	Kemampuan menjawab dan diskusi	\N	5	0	10	1	\N	2024-04-04 09:53:27	2	0
60ec96fd-9651-4dca-940e-3f97a035e141	271c46df-d1e1-440c-a3bd-5a865c088441	f0661ff0-e422-4a37-8e34-b487d39bac7e	Sikap	\N	5	0	10	1	\N	2024-04-04 09:53:30	2	0
340f7e71-e513-4a1c-b410-9aacf3652df2	271c46df-d1e1-440c-a3bd-5a865c088441	af6edd83-b741-499f-9f5f-3092fcea10e3	PEKERJAAN KLINIK	\N	0	0	80	1	\N	2024-04-04 09:53:30	0	1
9d59b92d-cc0c-4b5d-86ee-a13a65c743b3	cb433dc6-3620-4f49-9e68-cda03ebfd085	da054ee2-ed91-4aa8-9b10-473441593093	Data pasien	\N	1	0	0	1	\N	\N	0	0
81bf733a-1df8-4c27-a300-c80fb43094ee	cb433dc6-3620-4f49-9e68-cda03ebfd085	2383e153-b8b8-4d92-9630-4311f73296cb	Indikasi dan Pengisian Status	\N	0	0	0	1	\N	\N	0	1
3e18615c-b83c-41a7-9c4c-7860a9b66745	cb433dc6-3620-4f49-9e68-cda03ebfd085	29c3e582-6ae8-40db-a5e2-6bd34f63d4a4	Anamnesis	\N	1	0	0	1	\N	\N	0	0
70d94629-2fa9-429c-a93b-deb6c9b2571c	cb433dc6-3620-4f49-9e68-cda03ebfd085	eb89be64-2417-46b1-95cc-0c7483e9e605	Pemeriksaan KU, EO, IO	\N	1	0	0	1	\N	\N	0	0
509e070e-5301-4a7c-afaf-a98e9e1e2073	cb433dc6-3620-4f49-9e68-cda03ebfd085	30994d6f-28de-4ee9-a2bc-6bb6f0ccbd0d	Dokumentasi kondisi klinis awal	\N	1	0	0	1	\N	\N	0	0
a71ed9e5-c35b-4560-8757-a8af14f4a23a	cb433dc6-3620-4f49-9e68-cda03ebfd085	d771af19-b69c-40e3-9939-d327ce0b8fe6	Pembuatan model studi	\N	1	0	0	1	\N	\N	0	0
38de2990-7ce0-4df1-85a1-d8edf772e223	cb433dc6-3620-4f49-9e68-cda03ebfd085	a8cee5e1-d26e-498d-a7b6-f50a95d1aea3	Pembuatan model studi	\N	1	0	0	1	\N	\N	0	0
a9d0ef60-1583-4326-916d-a026ecd8f262	fac9a30d-6639-42bd-b7b8-6efc4756e8b9	52c00875-ff5b-40fa-bf03-2c57d786c6ec	PEKERJAAN KLINIK	\N	0	0	0	1	\N	\N	0	1
e172fd3e-afcf-4d58-bc05-6ad2080aed1f	fac9a30d-6639-42bd-b7b8-6efc4756e8b9	8520b176-2b33-459f-bf63-97a3e153e45d	Informed Consent	\N	5	0	0	1	\N	\N	0	0
68de1b77-98cc-4455-9918-ed5bd186baa7	fac9a30d-6639-42bd-b7b8-6efc4756e8b9	7236b2ff-217d-4998-9ef3-41b144e453f4	Proteksi Radiasi	\N	5	0	0	1	\N	\N	0	0
2ffb8d20-0d0f-421b-942b-0f385efec01a	fac9a30d-6639-42bd-b7b8-6efc4756e8b9	326fef6b-1ae2-4248-89a4-991922cbb136	Posisi Pasien	\N	5	0	0	1	\N	\N	0	0
beed9a23-be36-404b-ab27-e8b2141da6bc	fac9a30d-6639-42bd-b7b8-6efc4756e8b9	b9302baf-0246-4848-bc4c-16423150724b	Posisi Film	\N	5	0	0	1	\N	\N	0	0
f0ff5d51-4fe9-4486-965d-79f8dd9df69e	fac9a30d-6639-42bd-b7b8-6efc4756e8b9	169344ad-20af-4905-a2b5-7585fa61fb06	Posisi Tabung Xray	\N	5	0	0	1	\N	\N	0	0
8d38f1a9-244a-4e6d-8f0a-ac9834fa351f	fac9a30d-6639-42bd-b7b8-6efc4756e8b9	cdcbb703-4912-4b17-9b7b-be748d7ae249	Instruksi Pasien	\N	5	0	0	1	\N	\N	0	0
adbd048a-59b1-46df-ab2d-aaed1264d9f3	fac9a30d-6639-42bd-b7b8-6efc4756e8b9	ec8f5218-ecf9-461f-bbeb-2df2dad9285d	Exposure	\N	5	0	0	1	\N	\N	0	0
af1c4f58-580f-4245-a3ed-f0c4051da0e8	fac9a30d-6639-42bd-b7b8-6efc4756e8b9	0168ed48-f471-4cc5-a9e0-d51cb5737ac1	Prosesing	\N	5	0	0	1	\N	\N	0	0
12c15d4d-8488-4efb-9ac0-1827e32c566c	fac9a30d-6639-42bd-b7b8-6efc4756e8b9	fbac69ca-23dc-454d-b77f-9777a32d7a5d	SIKAP	\N	0	0	0	1	\N	\N	0	2
8e832611-a59f-4edc-8e09-76b552f8d0a7	fac9a30d-6639-42bd-b7b8-6efc4756e8b9	b5d94bd4-dcfc-4602-9297-c00847852dea	Inisiatif	\N	0	0	0	1	\N	\N	0	0
746d1bdd-96ff-466b-9c6c-81e15ea97650	fac9a30d-6639-42bd-b7b8-6efc4756e8b9	518e948d-dd5a-42a7-9cd8-df35a6510b88	Disiplin	\N	0	0	0	1	\N	\N	0	0
ac33b383-c001-4d57-9682-4f68bcb7b34d	fac9a30d-6639-42bd-b7b8-6efc4756e8b9	f603ceea-42c3-49a7-a9ab-0ee3227a2e72	Kejujuran	\N	0	0	0	1	\N	\N	0	0
b8f3b392-04fd-49f0-80b4-e3715fc9a6a2	fac9a30d-6639-42bd-b7b8-6efc4756e8b9	4009e0ce-7dc9-407e-be56-7292002c9f1f	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
a71ebb07-d18d-4cb4-bba5-3ae2591f4cd1	fac9a30d-6639-42bd-b7b8-6efc4756e8b9	24d7d73c-d5e9-4868-93b7-de9229b499a2	Kerjasama	\N	0	0	0	1	\N	\N	0	0
9436f24b-a77c-4da6-94e5-be1606864c67	fac9a30d-6639-42bd-b7b8-6efc4756e8b9	8c4c52d4-baf1-43d2-a6cb-cd62259bc6e7	Santun terhadap pasien	\N	0	0	0	1	\N	\N	0	0
9e0ee91e-8243-4141-871a-cc5b78470dae	fac9a30d-6639-42bd-b7b8-6efc4756e8b9	e9e25456-79dc-47b5-8e6d-5615706020ab	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
20ffb549-2c1f-4a44-834a-b84c9ed734f8	5e457df6-26e2-4f65-9acf-6cc958eea150	52c00875-ff5b-40fa-bf03-2c57d786c6ec	PEKERJAAN KLINIK	\N	0	0	0	1	\N	\N	0	1
4aaf4fb2-6e17-4268-ad29-6ad45627f741	5e457df6-26e2-4f65-9acf-6cc958eea150	8520b176-2b33-459f-bf63-97a3e153e45d	Informed Consent	\N	5	0	0	1	\N	\N	0	0
9949f6a9-2219-491b-8925-59a928695414	5e457df6-26e2-4f65-9acf-6cc958eea150	7236b2ff-217d-4998-9ef3-41b144e453f4	Proteksi Radiasi	\N	5	0	0	1	\N	\N	0	0
7c519863-c362-42ff-a510-769cc096d8e1	5e457df6-26e2-4f65-9acf-6cc958eea150	326fef6b-1ae2-4248-89a4-991922cbb136	Posisi Pasien	\N	5	0	0	1	\N	\N	0	0
ac9a07a0-8b76-4130-bbc3-b0e864e24877	5e457df6-26e2-4f65-9acf-6cc958eea150	b9302baf-0246-4848-bc4c-16423150724b	Posisi Film	\N	5	0	0	1	\N	\N	0	0
f6137f74-bc55-4488-b435-dd41322e301b	5e457df6-26e2-4f65-9acf-6cc958eea150	169344ad-20af-4905-a2b5-7585fa61fb06	Posisi Tabung Xray	\N	5	0	0	1	\N	\N	0	0
df3374a4-18c9-4efe-adfe-1bf7c1519053	5e457df6-26e2-4f65-9acf-6cc958eea150	cdcbb703-4912-4b17-9b7b-be748d7ae249	Instruksi Pasien	\N	5	0	0	1	\N	\N	0	0
709378ce-4957-4a2b-80c4-1388a758d13e	5e457df6-26e2-4f65-9acf-6cc958eea150	ec8f5218-ecf9-461f-bbeb-2df2dad9285d	Exposure	\N	5	0	0	1	\N	\N	0	0
7521dc53-c21a-48f8-a04b-0b393d01609e	5e457df6-26e2-4f65-9acf-6cc958eea150	0168ed48-f471-4cc5-a9e0-d51cb5737ac1	Prosesing	\N	5	0	0	1	\N	\N	0	0
953e1c48-11e3-4074-87a1-31b7fecdd437	5e457df6-26e2-4f65-9acf-6cc958eea150	fbac69ca-23dc-454d-b77f-9777a32d7a5d	SIKAP	\N	0	0	0	1	\N	\N	0	2
fa8af0c1-c79b-46c3-89bd-e16f16ab72e3	5e457df6-26e2-4f65-9acf-6cc958eea150	b5d94bd4-dcfc-4602-9297-c00847852dea	Inisiatif	\N	0	0	0	1	\N	\N	0	0
b91b516a-6ec5-41f1-bec5-eee42282d4d2	5e457df6-26e2-4f65-9acf-6cc958eea150	518e948d-dd5a-42a7-9cd8-df35a6510b88	Disiplin	\N	0	0	0	1	\N	\N	0	0
15c22188-e085-45a9-85e4-e9875b1d5881	5e457df6-26e2-4f65-9acf-6cc958eea150	f603ceea-42c3-49a7-a9ab-0ee3227a2e72	Kejujuran	\N	0	0	0	1	\N	\N	0	0
0f631dcb-c891-4454-9aa7-453297bf37cf	5e457df6-26e2-4f65-9acf-6cc958eea150	4009e0ce-7dc9-407e-be56-7292002c9f1f	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
53984eb7-c27c-4dea-b99c-39d7f92cc1e1	5e457df6-26e2-4f65-9acf-6cc958eea150	24d7d73c-d5e9-4868-93b7-de9229b499a2	Kerjasama	\N	0	0	0	1	\N	\N	0	0
917842e3-c66c-4691-9b71-38b5d7e8d366	5e457df6-26e2-4f65-9acf-6cc958eea150	8c4c52d4-baf1-43d2-a6cb-cd62259bc6e7	Santun terhadap pasien	\N	0	0	0	1	\N	\N	0	0
a2ef5988-ae1c-4c32-90b3-9f7b5e0a4b0f	5e457df6-26e2-4f65-9acf-6cc958eea150	e9e25456-79dc-47b5-8e6d-5615706020ab	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
89a45826-57db-4dde-9284-edba2684db1f	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	89d5f270-9bf7-43ce-a136-ea66e9cf168e	PEKERJAAN KLINIK	\N	0	0	0	1	\N	\N	0	1
a24004d7-d6fe-42e4-9f2c-45f525c24ef5	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	b1bde434-acb3-4d0e-b5ea-f22e0b0940ef	Menerima dan membaca rujukan pemeriksaan  radiograf periapikal, melakukan informed consent pada pasien dan  menulis  pada  buku  catatan  di  ruang Xray	\N	2	0	0	1	\N	\N	0	0
a222b993-2d70-49a8-9145-2c49c4c72db7	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	e9fe4b01-3356-4836-9b40-b6e2c1f4e246	Mempersiapkan alat xray intraoral, memilih lama eksposur pada panel kontrol dan film yang akan digunakan	\N	2	0	0	1	\N	\N	0	0
8d4dec4c-e765-48c4-8c1f-f1e26d5f7c96	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	8db2983a-640f-4476-bf2f-82fbecefe22a	Mempersilahkan  pasien  untuk  masuk  dan\nmenjelaskan kepada pasien prosedur pemeriksaan radiologis menggunakan teknik periapikal bisektris	\N	5	0	0	1	\N	\N	0	0
8551ed78-4740-4f38-b711-8937361f1775	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	f7f56eee-c3b2-4196-88fe-0b6ee19d17f4	Menggunakan Masker dan Sarung tangan	\N	2	0	0	1	\N	\N	0	0
e4c15a50-275e-4d1e-8cf3-816a4b03e20e	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	3be73c17-b7d0-40b8-a16f-a64591c5a9e5	Pasien diinstruksikan untuk memakai apron pelindung radiasi	\N	3	0	0	1	\N	\N	0	0
2999153e-be0c-46cc-9810-d447fc1dc578	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	457aae28-a96e-4450-a471-10ff880dccc5	Mempersilahkan pasien duduk di alat xray\ndan memposisikan kepala pasien: \na. Kepala bersandar pada headrest \nb. Bidang sagital tegak lurus lantai\nc. Bidang oklusal sejajar dengan lantai	\N	10	0	0	1	\N	\N	0	0
df118883-97c8-4e72-a80f-bed90c211350	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	40aa31de-c592-40b9-a2f0-99b45f6d0b94	Meletakkan film   intraoral kedalam mulut pasien, posisi objek yang akan diperiksa berada di  tengah film. Dot  film  berada  di insisal/oklusal gigi.	\N	5	0	0	1	\N	\N	0	0
aa75c421-c45e-4993-b454-31f8e645e508	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	5fdf51ed-449d-4e5f-a62f-4f9ed89e7c26	Jari pasien diarahkan untuk me-fiksasi film	\N	2	0	0	1	\N	\N	0	0
dab7f64f-a3b7-478a-b5b0-988f0cb0f7a1	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	26fb5ed1-f586-4805-b431-c73e532b850e	Mengatur Tabung eksposi pada:\na. Sudut vertikal disesuaikan objek yang akan diperiksa\nb. Sudut Horizontal disesuaikan objek yang akan diperiksa	\N	10	0	0	1	\N	\N	0	0
cb43b3a0-9b4d-4cb2-897f-6955da9b169b	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	ab29848c-1713-44d0-8ae6-8ff7a15a7d5d	Mengarahkan tabung eksposi sesuai dengan titik penetrasi objek.	\N	5	0	0	1	\N	\N	0	0
9314bd2b-866a-459e-86da-dec82ea2fe79	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	43f89f49-b5ff-47c6-8b41-f6532256ad31	Menginstruksikan pasien untuk tidak bergerak   dan   dan   menjelaskan   operator akan melakukan eksposi	\N	1	0	0	1	\N	\N	0	0
2cdd8aa5-94cd-463a-aa29-9fff61497c2f	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	cffbd13b-a92e-46f6-a65a-208136261a11	Memencet tombol eksposi	\N	1	0	0	1	\N	\N	0	0
205e1ff4-d636-4625-a476-e397ba2fc463	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	8f9a5f01-1723-4f02-952a-45ffffd2b050	Mengeluarkan  fim  dari  mulut  pasien  dan mempersilahkan   pasien   berdiri,   melepas apron pelindung radiasi.	\N	1	0	0	1	\N	\N	0	0
7f031799-1d85-48ea-8ab7-c62cdbeaa77e	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	666c4222-69c1-421b-8200-a10290440162	Mempersilahkan  pasien  kembali  ke  ruang tunggu untuk menunggu hasil radiograf.	\N	1	0	0	1	\N	\N	0	0
01d891e9-498b-4769-a38f-ce793ead18a0	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	c36494b4-8f30-4b6a-8020-84a37b4b80ca	SIKAP	\N	0	0	0	1	\N	\N	0	2
7bbaa356-0a6a-44c8-8456-ef24fa1fb5b2	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	fe20ae99-30ce-4cea-a454-37359f16c3bd	Inisiatif	\N	0	0	0	1	\N	\N	0	0
d6ce5db1-cb11-4397-9c77-59983a48bdd9	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	7eab875a-ad52-4ff2-971b-63e30724b03c	Disiplin	\N	0	0	0	1	\N	\N	0	0
8171cb0d-cc48-4124-9082-4843eaa6402b	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	af754f5e-cdef-4660-bc34-2bc09e06bc26	Kejujuran	\N	0	0	0	1	\N	\N	0	0
e7e49105-878c-45f3-ae5b-2b7508a25f8b	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	6a89654c-909f-43e3-ab47-d39c30037418	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
8ea724f6-418d-4aa0-b855-d0f30d5d3358	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	e63c6735-4cde-4093-98cd-0b2822c924ce	Kerjasama	\N	0	0	0	1	\N	\N	0	0
64fe45cf-d2df-4aeb-992f-3aa409665a90	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	dc8f07b1-45cd-4977-8ce2-312f5455bf19	Santun terhadap Pasien	\N	0	0	0	1	\N	\N	0	0
281703c8-7a05-45d9-b44a-06a08a0f195c	4a4ca4bb-6d4b-43b6-a998-46208bb475e7	a8e52691-7aa2-4ade-8323-e4e5495fb63b	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
ef24d194-22c8-4e30-915f-0d22bb5aea98	600a436c-314e-409a-ad11-9b7ce5b4eee2	52c00875-ff5b-40fa-bf03-2c57d786c6ec	PEKERJAAN KLINIK	\N	0	0	0	1	\N	\N	0	1
724e6f83-820f-4e6a-bbfc-7f715a930f92	600a436c-314e-409a-ad11-9b7ce5b4eee2	8520b176-2b33-459f-bf63-97a3e153e45d	Informed Consent	\N	5	0	0	1	\N	\N	0	0
b58f40c3-f9ac-4859-b641-fe6bd98448b2	600a436c-314e-409a-ad11-9b7ce5b4eee2	7236b2ff-217d-4998-9ef3-41b144e453f4	Proteksi Radiasi	\N	5	0	0	1	\N	\N	0	0
7eb381fd-c72b-46ef-b6bf-ee91704f7268	600a436c-314e-409a-ad11-9b7ce5b4eee2	326fef6b-1ae2-4248-89a4-991922cbb136	Posisi Pasien	\N	5	0	0	1	\N	\N	0	0
b41359ea-b2e4-43e8-90b2-84b89f0985f8	600a436c-314e-409a-ad11-9b7ce5b4eee2	b9302baf-0246-4848-bc4c-16423150724b	Posisi Film	\N	5	0	0	1	\N	\N	0	0
dcb588cc-1b54-450c-9a2b-01cb038632eb	600a436c-314e-409a-ad11-9b7ce5b4eee2	169344ad-20af-4905-a2b5-7585fa61fb06	Posisi Tabung Xray	\N	5	0	0	1	\N	\N	0	0
40dfbd0c-03ed-402d-acd2-ef1a0d631aa5	600a436c-314e-409a-ad11-9b7ce5b4eee2	cdcbb703-4912-4b17-9b7b-be748d7ae249	Instruksi Pasien	\N	5	0	0	1	\N	\N	0	0
99c48b9b-37be-4439-a0c6-4dc7c94d0d27	600a436c-314e-409a-ad11-9b7ce5b4eee2	ec8f5218-ecf9-461f-bbeb-2df2dad9285d	Exposure	\N	5	0	0	1	\N	\N	0	0
8180f5c8-21bd-457a-97d4-6508b860a7b9	600a436c-314e-409a-ad11-9b7ce5b4eee2	0168ed48-f471-4cc5-a9e0-d51cb5737ac1	Prosesing	\N	5	0	0	1	\N	\N	0	0
c5cec16b-9cde-4dfa-834d-9808a405ac1e	600a436c-314e-409a-ad11-9b7ce5b4eee2	fbac69ca-23dc-454d-b77f-9777a32d7a5d	SIKAP	\N	0	0	0	1	\N	\N	0	2
2799aad5-34cb-46cb-b5a1-4f2b4e4b816d	600a436c-314e-409a-ad11-9b7ce5b4eee2	b5d94bd4-dcfc-4602-9297-c00847852dea	Inisiatif	\N	0	0	0	1	\N	\N	0	0
3fde240e-b26e-4045-9b97-2e3d8a0aef3c	600a436c-314e-409a-ad11-9b7ce5b4eee2	518e948d-dd5a-42a7-9cd8-df35a6510b88	Disiplin	\N	0	0	0	1	\N	\N	0	0
f72578ac-dd63-41e0-99f9-4bfc4d556eff	600a436c-314e-409a-ad11-9b7ce5b4eee2	f603ceea-42c3-49a7-a9ab-0ee3227a2e72	Kejujuran	\N	0	0	0	1	\N	\N	0	0
9f12687d-7b83-4719-ae40-96270d5c6674	600a436c-314e-409a-ad11-9b7ce5b4eee2	4009e0ce-7dc9-407e-be56-7292002c9f1f	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
ee2db664-66b1-4c20-ac92-49cea1fea75c	600a436c-314e-409a-ad11-9b7ce5b4eee2	24d7d73c-d5e9-4868-93b7-de9229b499a2	Kerjasama	\N	0	0	0	1	\N	\N	0	0
7e08e588-4277-413a-a965-1a84589767dd	600a436c-314e-409a-ad11-9b7ce5b4eee2	8c4c52d4-baf1-43d2-a6cb-cd62259bc6e7	Santun terhadap pasien	\N	0	0	0	1	\N	\N	0	0
837ee1eb-2dad-4989-a26b-fed1da0beb59	600a436c-314e-409a-ad11-9b7ce5b4eee2	e9e25456-79dc-47b5-8e6d-5615706020ab	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
23b4d548-aa6d-42ad-94e7-16f1e3855963	688ed7e4-94c0-4122-8b6a-f6422b7cadc4	519f2d87-ede2-47fa-98f2-defab532bff3	PEKERJAAN KLINIK	\N	0	0	0	1	\N	\N	0	1
2e3b1529-67f3-49d9-88a3-6e99ae7080e2	688ed7e4-94c0-4122-8b6a-f6422b7cadc4	e4179566-439c-4d6e-b7a2-d1a32228978e	Informed Consent	\N	5	0	0	1	\N	\N	0	0
7227f0b9-34e4-475b-8ce0-b47ae8a4d1a9	688ed7e4-94c0-4122-8b6a-f6422b7cadc4	89382123-38f6-4e90-9526-30c7973bf572	Proteksi Radiasi	\N	5	0	0	1	\N	\N	0	0
2304249f-f396-4c75-adfd-7ff24947cf1f	688ed7e4-94c0-4122-8b6a-f6422b7cadc4	77ebd490-e367-4058-be7f-09eac021c473	Posisi Pasien	\N	5	0	0	1	\N	\N	0	0
8dff829d-4f32-4783-bba9-f5dda59a78f5	688ed7e4-94c0-4122-8b6a-f6422b7cadc4	ff6078d5-3b54-4bbd-a00d-cc66d3d1e259	Posisi Film	\N	5	0	0	1	\N	\N	0	0
40ce5c3b-2e62-4e90-98b6-bb21b7eb65e8	688ed7e4-94c0-4122-8b6a-f6422b7cadc4	b5280e46-b162-4b9e-bfd0-2f7ab634e077	Posisi Tabung Xray	\N	5	0	0	1	\N	\N	0	0
d18169cd-1478-4b57-be89-fba2559fccd7	688ed7e4-94c0-4122-8b6a-f6422b7cadc4	650d44b1-6c10-4a94-abf0-21702d538d39	Instruksi Pasien	\N	10	0	0	1	\N	\N	0	0
678c6d4e-49ed-4f47-8312-6393264bc4d6	688ed7e4-94c0-4122-8b6a-f6422b7cadc4	31d76d93-460c-4c22-8dc9-8ddac3055bd5	Exposure	\N	10	0	0	1	\N	\N	0	0
b7630836-0a4e-45bd-90ff-22a83a31e44c	688ed7e4-94c0-4122-8b6a-f6422b7cadc4	7644b9f2-1729-40eb-a6c5-abe2545a4555	SIKAP	\N	0	0	0	1	\N	\N	0	2
12e414c2-85e3-4ff2-8675-1fb55e22bb1d	688ed7e4-94c0-4122-8b6a-f6422b7cadc4	d3bbda49-4696-419d-a770-9e3e9e1bf01d	Inisiatif	\N	0	0	0	1	\N	\N	0	0
8097891e-35af-4ac3-850b-e23e4e34e74e	688ed7e4-94c0-4122-8b6a-f6422b7cadc4	80a50b4b-28b6-4c24-b1dd-38d04e446437	Disiplin	\N	0	0	0	1	\N	\N	0	0
b0ce127e-7488-4770-93a4-daaada40fe67	688ed7e4-94c0-4122-8b6a-f6422b7cadc4	823d56f5-8d50-4ce0-98e1-a6c3eedc143a	Kejujuran	\N	0	0	0	1	\N	\N	0	0
c91fbf8b-849d-4816-a188-af8a4ab20472	688ed7e4-94c0-4122-8b6a-f6422b7cadc4	9e32d68a-0eb2-48c1-bc52-4a39d4f0d018	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
d19c624f-f0fe-4443-b053-21f56a2a27b7	688ed7e4-94c0-4122-8b6a-f6422b7cadc4	ed11558f-8782-44bc-86df-68eced45d5e7	Kerjasama	\N	0	0	0	1	\N	\N	0	0
2a5be541-6555-45c2-a859-3dbf83797973	688ed7e4-94c0-4122-8b6a-f6422b7cadc4	95e9b0c0-f682-470b-95fe-69472cd7a1a9	Santun terhadap pasien	\N	0	0	0	1	\N	\N	0	0
5ed875cd-dbac-49ee-900c-7f333b47de61	688ed7e4-94c0-4122-8b6a-f6422b7cadc4	828a05e8-09ca-404e-ad19-37ea6cf19295	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
73bcca25-250e-492f-bfc8-9bb7669829df	14e4098d-2a3e-4245-8353-bd4ed351e6a6	e4179566-439c-4d6e-b7a2-d1a32228978e	Informed Consent	\N	5	0	10	1	\N	2024-04-23 18:00:38	2	0
9bbe1c16-ed5d-48fa-8a1a-9877b420dc5e	14e4098d-2a3e-4245-8353-bd4ed351e6a6	828a05e8-09ca-404e-ad19-37ea6cf19295	Santun terhadap dosen	\N	1	0	2	1	\N	2024-04-23 19:06:01	2	0
e60d9d37-baa1-47ef-8bf4-2a57740c790f	14e4098d-2a3e-4245-8353-bd4ed351e6a6	7644b9f2-1729-40eb-a6c5-abe2545a4555	SIKAP	\N	0	0	14	1	\N	2024-04-23 19:06:03	0	2
ab49f191-0fef-4734-8117-7c25b66303ed	14e4098d-2a3e-4245-8353-bd4ed351e6a6	650d44b1-6c10-4a94-abf0-21702d538d39	Instruksi Pasien	\N	10	0	20	1	\N	2024-04-23 20:28:30	2	0
7090fb4c-c894-4533-b63b-faf80a86ada4	14e4098d-2a3e-4245-8353-bd4ed351e6a6	89382123-38f6-4e90-9526-30c7973bf572	Proteksi Radiasi	\N	5	0	10	1	\N	2024-04-23 18:15:13	2	0
f0d6445b-cd2d-42fe-a5c8-23e18ce0d5ba	14e4098d-2a3e-4245-8353-bd4ed351e6a6	ff6078d5-3b54-4bbd-a00d-cc66d3d1e259	Posisi Film	\N	5	0	5	1	\N	2024-04-23 20:38:08	1	0
fcf682b8-7bc6-4b80-9cdd-9d3abb14d5f7	14e4098d-2a3e-4245-8353-bd4ed351e6a6	b5280e46-b162-4b9e-bfd0-2f7ab634e077	Posisi Tabung Xray	\N	5	0	10	1	\N	2024-04-23 18:16:11	2	0
af3dd0c9-5ba8-45fc-ba37-3d436cebdccf	14e4098d-2a3e-4245-8353-bd4ed351e6a6	31d76d93-460c-4c22-8dc9-8ddac3055bd5	Exposure	\N	10	0	20	1	\N	2024-04-23 18:17:06	2	0
b12c870d-acc1-4be9-af97-686eff753ea5	14e4098d-2a3e-4245-8353-bd4ed351e6a6	d3bbda49-4696-419d-a770-9e3e9e1bf01d	Inisiatif	\N	1	0	2	1	\N	2024-04-23 19:02:09	2	0
8c22098f-0826-4764-af88-17c6834af620	14e4098d-2a3e-4245-8353-bd4ed351e6a6	77ebd490-e367-4058-be7f-09eac021c473	Posisi Pasien	\N	5	0	10	1	\N	2024-04-23 20:47:21	2	0
cfb3c513-2eb7-4b8a-80ef-6312476550d6	14e4098d-2a3e-4245-8353-bd4ed351e6a6	519f2d87-ede2-47fa-98f2-defab532bff3	PEKERJAAN KLINIK	\N	0	0	85	1	\N	2024-04-23 20:47:23	0	1
671917be-7191-475b-bf4b-1386ce326238	14e4098d-2a3e-4245-8353-bd4ed351e6a6	80a50b4b-28b6-4c24-b1dd-38d04e446437	Disiplin	\N	1	0	2	1	\N	2024-04-23 19:02:59	2	0
d285b97f-f9b6-4c88-9098-8d605bc60121	14e4098d-2a3e-4245-8353-bd4ed351e6a6	823d56f5-8d50-4ce0-98e1-a6c3eedc143a	Kejujuran	\N	1	0	2	1	\N	2024-04-23 19:04:29	2	0
08e3aefc-af39-4c04-8586-f64dbaa7d805	14e4098d-2a3e-4245-8353-bd4ed351e6a6	9e32d68a-0eb2-48c1-bc52-4a39d4f0d018	Tanggung Jawab	\N	1	0	2	1	\N	2024-04-23 19:04:50	2	0
0b5e427e-0cb8-4152-ab94-fa9608cde1ac	14e4098d-2a3e-4245-8353-bd4ed351e6a6	ed11558f-8782-44bc-86df-68eced45d5e7	Kerjasama	\N	1	0	2	1	\N	2024-04-23 19:05:19	2	0
3da12a06-2624-429b-9ba2-79d6c4b17299	14e4098d-2a3e-4245-8353-bd4ed351e6a6	95e9b0c0-f682-470b-95fe-69472cd7a1a9	Santun terhadap pasien	\N	1	0	2	1	\N	2024-04-23 19:05:40	2	0
06a1a4f4-3f7d-409b-9939-fcb8a87208f1	7884f9e5-09e0-4b8a-a758-0d0cfcc7a96c	519f2d87-ede2-47fa-98f2-defab532bff3	PEKERJAAN KLINIK	\N	0	0	0	1	\N	\N	0	1
b254c29b-1575-4f52-a13d-00ef97b4fc85	7884f9e5-09e0-4b8a-a758-0d0cfcc7a96c	e4179566-439c-4d6e-b7a2-d1a32228978e	Informed Consent	\N	5	0	0	1	\N	\N	0	0
cebbe2c7-6201-459b-a9ce-9a817b8bf993	7884f9e5-09e0-4b8a-a758-0d0cfcc7a96c	89382123-38f6-4e90-9526-30c7973bf572	Proteksi Radiasi	\N	5	0	0	1	\N	\N	0	0
469d05e1-ec38-48e9-9ccc-5cd73ef42b9e	7884f9e5-09e0-4b8a-a758-0d0cfcc7a96c	77ebd490-e367-4058-be7f-09eac021c473	Posisi Pasien	\N	5	0	0	1	\N	\N	0	0
2d6fdac0-d770-4abd-9aa2-29091001312e	7884f9e5-09e0-4b8a-a758-0d0cfcc7a96c	ff6078d5-3b54-4bbd-a00d-cc66d3d1e259	Posisi Film	\N	5	0	0	1	\N	\N	0	0
cc3b08da-0e97-4a65-8ef4-86a0fbb2bee6	7884f9e5-09e0-4b8a-a758-0d0cfcc7a96c	b5280e46-b162-4b9e-bfd0-2f7ab634e077	Posisi Tabung Xray	\N	5	0	0	1	\N	\N	0	0
47cd3402-e0f3-4b88-bb76-899f1cf233ac	7884f9e5-09e0-4b8a-a758-0d0cfcc7a96c	650d44b1-6c10-4a94-abf0-21702d538d39	Instruksi Pasien	\N	10	0	0	1	\N	\N	0	0
dd7c78fe-6163-4fa9-b5e8-ef8753dc3a25	7884f9e5-09e0-4b8a-a758-0d0cfcc7a96c	31d76d93-460c-4c22-8dc9-8ddac3055bd5	Exposure	\N	10	0	0	1	\N	\N	0	0
70e11666-22b7-436d-a15b-58dcb71e4f46	7884f9e5-09e0-4b8a-a758-0d0cfcc7a96c	7644b9f2-1729-40eb-a6c5-abe2545a4555	SIKAP	\N	0	0	0	1	\N	\N	0	2
4b5931e7-a456-407e-8045-0cf9155c96c5	7884f9e5-09e0-4b8a-a758-0d0cfcc7a96c	d3bbda49-4696-419d-a770-9e3e9e1bf01d	Inisiatif	\N	0	0	0	1	\N	\N	0	0
f60af091-64fb-444e-b75b-b3aa0a31ed88	7884f9e5-09e0-4b8a-a758-0d0cfcc7a96c	80a50b4b-28b6-4c24-b1dd-38d04e446437	Disiplin	\N	0	0	0	1	\N	\N	0	0
d3b8dc51-c4ea-4192-8959-9e1cc1056d41	7884f9e5-09e0-4b8a-a758-0d0cfcc7a96c	823d56f5-8d50-4ce0-98e1-a6c3eedc143a	Kejujuran	\N	0	0	0	1	\N	\N	0	0
fa5f4c88-ae49-4163-a25a-616ebebe83e0	7884f9e5-09e0-4b8a-a758-0d0cfcc7a96c	9e32d68a-0eb2-48c1-bc52-4a39d4f0d018	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
e7dbd842-73db-49f0-8b0b-d9626cac572d	7884f9e5-09e0-4b8a-a758-0d0cfcc7a96c	ed11558f-8782-44bc-86df-68eced45d5e7	Kerjasama	\N	0	0	0	1	\N	\N	0	0
b7bc5a6b-5f75-4d1c-8886-921f11eedb7f	7884f9e5-09e0-4b8a-a758-0d0cfcc7a96c	95e9b0c0-f682-470b-95fe-69472cd7a1a9	Santun terhadap pasien	\N	0	0	0	1	\N	\N	0	0
23daa1b2-48fb-455d-a675-56592497980c	7884f9e5-09e0-4b8a-a758-0d0cfcc7a96c	828a05e8-09ca-404e-ad19-37ea6cf19295	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
66644204-1db3-4725-a65c-3d25ceded01c	bff75338-d1a5-4d8f-8e40-cb13f74e0765	8f52a0c4-e0af-4790-9dfe-c66e1e59a769	PEKERJAAN KLINIK	\N	0	0	0	1	\N	\N	0	1
9ffac84c-8200-44bb-982f-2df5aa54088d	bff75338-d1a5-4d8f-8e40-cb13f74e0765	2141ceeb-182a-43b0-bd7a-52824be88de3	Menilai kualitas radiograf :\n1.\tkontras radiograf : nilai kontras yang baik jika gambaran jaringan terlihat dengan jelas (radiopak dan radiolusen jelas)\n2.\tKetajaman (Sharpness) Radiograf : Ketajaman (sharpness) didefinisikan sebagai kemampuan dari suatu radiograf untuk menjelaskan tepi atau batas-batas dari objek yang tampak\n3.\tDetail Radiograf : Detail radiograf menjelaskan tentang bagian terkecil dari objek masih dapat tervisualisasi dengan baik pada radiograf (perbedaan tiap objek misal: dentin, email)\n4.\tDensitas suatu radiograf  :  keseluruhan derajat penghitaman pada sebuah film/reseptor yang telah diberikan paparan radiasi diukur sebagai densitas optik dari area suatu film. Densitas ini bergantung pada ketebalan objek, densitas objek, dan tingkat pemaparan sinar x.\n5.\tBrightness : keseimbangan antara warna terang dan gelap pada suatu gambaran radiografi.	\N	10	0	0	1	\N	\N	0	0
7b2bab3e-6255-4334-80f7-67ac5ad4cbe2	bff75338-d1a5-4d8f-8e40-cb13f74e0765	46f34477-d061-415d-a758-cce20808b860	Interpretasi mahkota :\n1. Densitas: radioopak/radiolusen\n2. Lokasi: oklusal/proximal/cervikal\n3. Kedalaman: meliputi elemen gigi apa (sampai email/dentin/pulpa)	\N	2	0	0	1	\N	\N	0	0
9792bd1e-8397-4417-ad08-fe625afa3a64	bff75338-d1a5-4d8f-8e40-cb13f74e0765	ed973d87-518c-4955-b6b6-ddbe882874a7	Interpretasi akar:\n1. Jumlah akar : tunggal(1)/2,3\n2. Bentuk akar : divergen/konvergen/Dilaserasi\n3.\tDensitas : radioopak/radiolusen	\N	2	0	0	1	\N	\N	0	0
f8ae03b6-eb82-4b19-b587-8e22625de20c	bff75338-d1a5-4d8f-8e40-cb13f74e0765	f647001a-5c86-43bf-9106-83598fff9516	Interpretasi ruang membran periodontal :\n1. DBN/menghilang/ melebar\n2. Lokasi : seluruh akar/ 1/3 apikal  dll	\N	2	0	0	1	\N	\N	0	0
02329c48-3f78-4ab7-964e-d631711d226e	bff75338-d1a5-4d8f-8e40-cb13f74e0765	f027a75a-593b-410f-a042-2229183972f0	Interpretasi laminadura :\n1. DBN/terputus/menghilang/menebal\n2. Lokasi : seluruh akar/ 1/3 apikal  dll	\N	2	0	0	1	\N	\N	0	0
fd4311c6-0604-43dd-abff-0fd443a2db36	bff75338-d1a5-4d8f-8e40-cb13f74e0765	3a435e7d-86b2-4f46-9505-04dc3e37b787	Interpretasi puncak tulang alveolar :\n1.DBN(1-3mm)/mengalami penurunan\n2.Tipe penurunan (vertikal/horizontal)\n3.Berapa mm penurunan puncak tulang alveolar dari CEJ	\N	2	0	0	1	\N	\N	0	0
a8906040-cf06-44f8-84f5-04bfb4f9f01a	bff75338-d1a5-4d8f-8e40-cb13f74e0765	b410da6f-73e1-4ecf-8fb8-cadda23be168	Interpretasi furkasi : \n1. pelebaran membran\n2. Penurunan tulang alveor\n3 radiolusen/radioopak/DBN	\N	2	0	0	1	\N	\N	0	0
b41d2890-e955-4236-af95-04f76307a59a	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	f603ceea-42c3-49a7-a9ab-0ee3227a2e72	Kejujuran	\N	0	0	0	1	\N	\N	0	0
3a58de7c-e623-41dc-b763-510e882ef30a	bff75338-d1a5-4d8f-8e40-cb13f74e0765	c6df03b3-84c9-4d0c-bb0d-8f76f36c7419	Interpretasi periapikal \n1. Site : lokasi at regio apa\n2. Size : ukuran x.y mm/ sebesar kacang polong dll\n3. Shape : bulat/oval/reguler/irreguler\n4. Symmetry\n5. Borders : batas jelas dan tegas/ jelas tidak tegas/ tidak jelas dan tidak tegas/ reguler/irreguler\n6. Contents :\nradiolusen/radioopak/mixed\n7. Associations : hub/efek terhadap struktur lain disekitarnya\n8. Jumlah : unilokuler/multilokuler	\N	10	0	0	1	\N	\N	0	0
a93dcd25-5039-4825-ad07-51a430892d3d	bff75338-d1a5-4d8f-8e40-cb13f74e0765	57660cb0-2e51-429b-8a0e-7451e240581b	Membuat Kesan :\nMenyebutkan kelainan pada setiap elemen.\n“Terdapat kelainan pada mahkota, akar...”	\N	3	0	0	1	\N	\N	0	0
3aea434c-cd09-4c19-a774-1def24a4aafe	bff75338-d1a5-4d8f-8e40-cb13f74e0765	7328821c-6c9d-4d15-90c2-bce444ccfca0	Menentukan suspect radiodiagnosis	\N	10	0	0	1	\N	\N	0	0
80d0338c-9a7a-4857-81ef-3f87cc6bb98d	bff75338-d1a5-4d8f-8e40-cb13f74e0765	d01d7288-4615-49ae-a513-91f0de6eeda6	Menentukan differensial diagnosis	\N	5	0	0	1	\N	\N	0	0
410d2519-a694-45aa-9e74-69b7e30c2239	bff75338-d1a5-4d8f-8e40-cb13f74e0765	5cb67473-39fb-45f1-a078-99115cbc3cda	SIKAP	\N	0	0	0	1	\N	\N	0	2
838d223b-5bec-44d2-b1e3-09db06647e49	bff75338-d1a5-4d8f-8e40-cb13f74e0765	6ea2b1b7-021a-4a4a-9680-70c1eeba4d66	Inisiatif	\N	0	0	0	1	\N	\N	0	0
32a54075-e621-4011-8562-7fcc1799ef9b	bff75338-d1a5-4d8f-8e40-cb13f74e0765	eb443a45-4e06-4d2a-8165-f9f7f8e84202	Disiplin	\N	0	0	0	1	\N	\N	0	0
8ec0dff2-92b2-4d4d-b390-7fec8903dee9	bff75338-d1a5-4d8f-8e40-cb13f74e0765	6e5b56e6-de53-4d93-9e09-2a55ab432263	Kejujuran	\N	0	0	0	1	\N	\N	0	0
b6feadb6-c448-41f8-85e6-c0439f1d453f	bff75338-d1a5-4d8f-8e40-cb13f74e0765	6f32d2d7-3f87-4d02-b21a-04e6f343e737	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
bfc64405-3916-463e-8e71-7d92dd268381	bff75338-d1a5-4d8f-8e40-cb13f74e0765	e77bd997-c5c6-4ede-b247-058097ee1c66	Kerjasama	\N	0	0	0	1	\N	\N	0	0
f6ffa9dd-2bf5-495e-a9b3-f2b070db1258	bff75338-d1a5-4d8f-8e40-cb13f74e0765	047b171d-76b9-4841-bb65-fc760627fcb5	Santun terhadap pasien	\N	0	0	0	1	\N	\N	0	0
8a6f426e-96dc-4e77-a362-7dfeaf69aa4a	bff75338-d1a5-4d8f-8e40-cb13f74e0765	600cbb17-16fc-4180-ba24-109974958040	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
7c5dac25-de67-41ab-b1f3-47a6974c366a	8f77d45e-f0ab-4909-90c1-14d37873fe1a	782aa962-1ddb-4442-9db2-fa43946848bd	SIKAP	\N	0	0	0	1	\N	\N	0	2
2d75a0a9-3dd4-491f-8abe-0610ac8d9c3a	8f77d45e-f0ab-4909-90c1-14d37873fe1a	0209f583-008f-414b-bcf7-7a389dbf224d	Inisiatif	\N	0	0	0	1	\N	\N	0	0
766421f1-8f26-4e31-8ed3-5299a48f90ff	8f77d45e-f0ab-4909-90c1-14d37873fe1a	a889ca74-b784-43e1-90c0-5833b32898df	Disiplin	\N	0	0	0	1	\N	\N	0	0
8920752d-e70e-447d-8336-2da8df9e9a58	8f77d45e-f0ab-4909-90c1-14d37873fe1a	d70c5578-b960-4272-9e36-01bfc68586d5	Kejujuran	\N	0	0	0	1	\N	\N	0	0
fa11282e-dcc2-4afa-81c4-9bb8e81c8d5a	8f77d45e-f0ab-4909-90c1-14d37873fe1a	47a4695a-8eca-4d21-8ae5-dee4e708794d	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
39a77cf2-075d-4766-833f-8d8de1146c6f	8f77d45e-f0ab-4909-90c1-14d37873fe1a	a91e2a00-a885-49d4-8ca0-b442b3b10dfd	Kerjasama	\N	0	0	0	1	\N	\N	0	0
30d5fd86-d731-468a-904d-807b1eb08674	8f77d45e-f0ab-4909-90c1-14d37873fe1a	8a748853-439a-49be-8dd8-26745b5e3bdb	Santun terhadap Pasien	\N	0	0	0	1	\N	\N	0	0
bd559315-4f80-4e32-af16-08f473f118d3	8f77d45e-f0ab-4909-90c1-14d37873fe1a	4314ce0c-e122-44fe-807b-00c5bbdb196a	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
b61f9c2c-037e-4fe5-b1b5-36104653987b	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	89d5f270-9bf7-43ce-a136-ea66e9cf168e	PEKERJAAN KLINIK	\N	0	0	0	1	\N	\N	0	1
bdaf87d0-0cc8-4e2c-b056-bdbcc1ded24c	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	52c00875-ff5b-40fa-bf03-2c57d786c6ec	PEKERJAAN KLINIK	\N	0	0	0	1	\N	\N	0	1
db48dee2-386f-4a12-bdec-74ed7f5d6ae7	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	b1bde434-acb3-4d0e-b5ea-f22e0b0940ef	Menerima dan membaca rujukan pemeriksaan  radiograf periapikal, melakukan informed consent pada pasien dan  menulis  pada  buku  catatan  di  ruang Xray	\N	2	0	0	1	\N	\N	0	0
28c4acb7-3eba-4cf8-bf78-c32593c660bf	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	8520b176-2b33-459f-bf63-97a3e153e45d	Informed Consent	\N	5	0	0	1	\N	\N	0	0
1894d969-dc7e-469d-a3ca-01db6ba01454	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	e9fe4b01-3356-4836-9b40-b6e2c1f4e246	Mempersiapkan alat xray intraoral, memilih lama eksposur pada panel kontrol dan film yang akan digunakan	\N	2	0	0	1	\N	\N	0	0
8971ec8c-c8d3-4ca3-a5a4-5adafabe460e	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	7236b2ff-217d-4998-9ef3-41b144e453f4	Proteksi Radiasi	\N	5	0	0	1	\N	\N	0	0
59774ef6-60ee-4a59-9cc1-4f9218d66a50	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	326fef6b-1ae2-4248-89a4-991922cbb136	Posisi Pasien	\N	5	0	0	1	\N	\N	0	0
9fdb747a-1030-4388-a5ba-689b23297920	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	8db2983a-640f-4476-bf2f-82fbecefe22a	Mempersilahkan  pasien  untuk  masuk  dan\nmenjelaskan kepada pasien prosedur pemeriksaan radiologis menggunakan teknik periapikal bisektris	\N	5	0	0	1	\N	\N	0	0
5abde693-ee01-48a4-8547-0bd8ee292b90	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	f7f56eee-c3b2-4196-88fe-0b6ee19d17f4	Menggunakan Masker dan Sarung tangan	\N	2	0	0	1	\N	\N	0	0
a9d4e1ac-0a78-4edd-96fd-8d73547c6ad2	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	b9302baf-0246-4848-bc4c-16423150724b	Posisi Film	\N	5	0	0	1	\N	\N	0	0
08b26499-f4cc-4936-95e8-36bc05c97284	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	3be73c17-b7d0-40b8-a16f-a64591c5a9e5	Pasien diinstruksikan untuk memakai apron pelindung radiasi	\N	3	0	0	1	\N	\N	0	0
b8ed2013-e674-4bfa-906a-ec232db42613	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	169344ad-20af-4905-a2b5-7585fa61fb06	Posisi Tabung Xray	\N	5	0	0	1	\N	\N	0	0
2942dbce-5e6d-441c-ad55-409bf6784e47	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	457aae28-a96e-4450-a471-10ff880dccc5	Mempersilahkan pasien duduk di alat xray\ndan memposisikan kepala pasien: \na. Kepala bersandar pada headrest \nb. Bidang sagital tegak lurus lantai\nc. Bidang oklusal sejajar dengan lantai	\N	10	0	0	1	\N	\N	0	0
09db35fa-b0c1-4b80-85dd-b0c694916bc9	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	cdcbb703-4912-4b17-9b7b-be748d7ae249	Instruksi Pasien	\N	5	0	0	1	\N	\N	0	0
7710bcc2-7fcf-430d-9eec-356a6a9fdb92	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	40aa31de-c592-40b9-a2f0-99b45f6d0b94	Meletakkan film   intraoral kedalam mulut pasien, posisi objek yang akan diperiksa berada di  tengah film. Dot  film  berada  di insisal/oklusal gigi.	\N	5	0	0	1	\N	\N	0	0
6443a540-d263-4a5a-a8e3-46a73530a111	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	ec8f5218-ecf9-461f-bbeb-2df2dad9285d	Exposure	\N	5	0	0	1	\N	\N	0	0
781d1bcc-ddff-4548-9b55-c1517332ddfc	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	0168ed48-f471-4cc5-a9e0-d51cb5737ac1	Prosesing	\N	5	0	0	1	\N	\N	0	0
41978ea0-17e7-4c97-bb62-0797c3e44132	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	5fdf51ed-449d-4e5f-a62f-4f9ed89e7c26	Jari pasien diarahkan untuk me-fiksasi film	\N	2	0	0	1	\N	\N	0	0
bd88db7b-0c6b-4e43-ba73-cdc39362f758	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	26fb5ed1-f586-4805-b431-c73e532b850e	Mengatur Tabung eksposi pada:\na. Sudut vertikal disesuaikan objek yang akan diperiksa\nb. Sudut Horizontal disesuaikan objek yang akan diperiksa	\N	10	0	0	1	\N	\N	0	0
59c7a056-1d8b-494b-bcba-8075001e6ef7	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	ab29848c-1713-44d0-8ae6-8ff7a15a7d5d	Mengarahkan tabung eksposi sesuai dengan titik penetrasi objek.	\N	5	0	0	1	\N	\N	0	0
023c20be-5e69-4b5e-b873-2976c6f07fd9	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	43f89f49-b5ff-47c6-8b41-f6532256ad31	Menginstruksikan pasien untuk tidak bergerak   dan   dan   menjelaskan   operator akan melakukan eksposi	\N	1	0	0	1	\N	\N	0	0
5c60f829-16d8-409b-9e04-cf876442e878	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	cffbd13b-a92e-46f6-a65a-208136261a11	Memencet tombol eksposi	\N	1	0	0	1	\N	\N	0	0
7e7cd481-b36b-49d8-9151-818923caa3d4	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	8f9a5f01-1723-4f02-952a-45ffffd2b050	Mengeluarkan  fim  dari  mulut  pasien  dan mempersilahkan   pasien   berdiri,   melepas apron pelindung radiasi.	\N	1	0	0	1	\N	\N	0	0
637b9b94-f159-4efa-b3ae-4de049992db3	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	666c4222-69c1-421b-8200-a10290440162	Mempersilahkan  pasien  kembali  ke  ruang tunggu untuk menunggu hasil radiograf.	\N	1	0	0	1	\N	\N	0	0
38c1f192-a9f7-49f3-9b52-16cef6fdea39	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	c36494b4-8f30-4b6a-8020-84a37b4b80ca	SIKAP	\N	0	0	0	1	\N	\N	0	2
c3038d3f-df04-480d-bde8-2376891448ca	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	fbac69ca-23dc-454d-b77f-9777a32d7a5d	SIKAP	\N	0	0	0	1	\N	\N	0	2
f70e0d14-56b4-4e23-b011-7446165eb4f4	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	fe20ae99-30ce-4cea-a454-37359f16c3bd	Inisiatif	\N	0	0	0	1	\N	\N	0	0
a13833d9-fa06-46ec-a698-023afba41ad9	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	b5d94bd4-dcfc-4602-9297-c00847852dea	Inisiatif	\N	0	0	0	1	\N	\N	0	0
f5d30649-82c3-4559-8d5e-1878c7c3bac8	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	518e948d-dd5a-42a7-9cd8-df35a6510b88	Disiplin	\N	0	0	0	1	\N	\N	0	0
363ce50a-7afb-41a8-af38-9dd0600fd254	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	7eab875a-ad52-4ff2-971b-63e30724b03c	Disiplin	\N	0	0	0	1	\N	\N	0	0
fc85d94e-c257-44f2-884c-5232cdc567a7	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	af754f5e-cdef-4660-bc34-2bc09e06bc26	Kejujuran	\N	0	0	0	1	\N	\N	0	0
721c9fff-4122-431b-a37e-9ad69b5d2747	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	6a89654c-909f-43e3-ab47-d39c30037418	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
b70ef0ee-bde9-4adf-8f42-0442b58c12c2	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	4009e0ce-7dc9-407e-be56-7292002c9f1f	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
3bbd1996-6eab-468f-a2a8-c8bbb6590d84	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	e63c6735-4cde-4093-98cd-0b2822c924ce	Kerjasama	\N	0	0	0	1	\N	\N	0	0
ed439ed9-4ced-4901-bf94-24c600fe6bec	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	24d7d73c-d5e9-4868-93b7-de9229b499a2	Kerjasama	\N	0	0	0	1	\N	\N	0	0
88b5df4b-c115-47a0-8201-589b0ad1e886	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	dc8f07b1-45cd-4977-8ce2-312f5455bf19	Santun terhadap Pasien	\N	0	0	0	1	\N	\N	0	0
ada70082-bef6-466c-b97e-831c1b05608d	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	8c4c52d4-baf1-43d2-a6cb-cd62259bc6e7	Santun terhadap pasien	\N	0	0	0	1	\N	\N	0	0
256960a3-4ce3-40cc-8e6f-80438db18ae4	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	a8e52691-7aa2-4ade-8323-e4e5495fb63b	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
5b802b99-2eca-49cc-880c-3d95f50887a7	f5eadc06-ef8c-4ca3-ae06-dc5f02c14c79	e9e25456-79dc-47b5-8e6d-5615706020ab	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
a60dc00c-82bd-4392-80b7-415b59c637cf	fd4b7500-d73b-419d-acd1-fed1046d6138	599152ae-139e-4752-8449-bffbcd9d0bec	PEKERJAAN KLINIK	\N	0	0	0	1	\N	\N	0	1
756022b1-bbb0-480d-a2df-8b6cf730130e	fd4b7500-d73b-419d-acd1-fed1046d6138	d4201e53-3afb-4d0a-b2dc-bcd5c496fa3c	Bentuk dan Ukuran	\N	10	0	0	1	\N	\N	0	0
c541d6bf-9f96-4681-b3ab-13150d8c453b	fd4b7500-d73b-419d-acd1-fed1046d6138	8481216e-1fac-4ea6-8771-143ebc9c27d3	Kondisi radiograf	\N	5	0	0	1	\N	\N	0	0
795695a9-e118-4270-93d5-6c1af3c4f754	fd4b7500-d73b-419d-acd1-fed1046d6138	d4a10422-327d-4145-bdf9-35273f045d43	Posisi Objek	\N	5	0	0	1	\N	\N	0	0
f520f12f-ebce-4e18-8c64-1f1f6fefdfcc	fd4b7500-d73b-419d-acd1-fed1046d6138	e2965e26-c22c-444f-acfd-0435e19bd2c3	Posisi Penempatan Film	\N	5	0	0	1	\N	\N	0	0
4d594cd7-d120-4065-9b7d-1ee33c0b2ad3	fd4b7500-d73b-419d-acd1-fed1046d6138	bb6d820f-763d-4d37-8e7d-6b7e0b39c9fa	SIKAP	\N	0	0	0	1	\N	\N	0	2
a181ff11-ee0a-4af4-90af-f10deb186efa	fd4b7500-d73b-419d-acd1-fed1046d6138	4a3025aa-89ef-47e7-bc9b-e225961d5e96	Inisiatif	\N	0	0	0	1	\N	\N	0	0
1f62ff28-5e16-4881-8a49-c7c2263c7bf6	fd4b7500-d73b-419d-acd1-fed1046d6138	cb3c9233-1a22-4e9e-bee8-52ad0ce7f431	Disiplin	\N	0	0	0	1	\N	\N	0	0
f1d016b8-bf8d-4005-bfc0-5e10cafb16bc	fd4b7500-d73b-419d-acd1-fed1046d6138	49dd2a5e-d385-4e69-833d-e5531617f909	Kejujuran	\N	0	0	0	1	\N	\N	0	0
176a3832-64f6-4bc2-8e96-5cf9b57f03a8	fd4b7500-d73b-419d-acd1-fed1046d6138	b9241d97-c626-4f27-bd8d-06d407117390	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
7b7b3112-b048-48dd-897a-81f0a3a275c8	fd4b7500-d73b-419d-acd1-fed1046d6138	cba0017f-6ef6-4e41-8865-596d223f4cc8	Kerjasama	\N	0	0	0	1	\N	\N	0	0
3f52de2a-da1b-446b-bd2f-8c8da4925270	fd4b7500-d73b-419d-acd1-fed1046d6138	bcce051c-8bfe-4622-bae7-0edf1602f9e8	Santun terhadap pasien	\N	0	0	0	1	\N	\N	0	0
dab6d032-3b18-42e7-8fbc-8b562ff4d0cf	fd4b7500-d73b-419d-acd1-fed1046d6138	64a1ec32-4595-40e3-977f-53d0e5454c12	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
4b928c68-c894-441d-89ab-23c5cf2dbce1	65584d58-1889-4d9b-a5b9-70c940c529d8	782aa962-1ddb-4442-9db2-fa43946848bd	SIKAP	\N	0	0	0	1	\N	\N	0	2
25472adf-59b8-433f-87e0-f86639ba726b	65584d58-1889-4d9b-a5b9-70c940c529d8	0209f583-008f-414b-bcf7-7a389dbf224d	Inisiatif	\N	0	0	0	1	\N	\N	0	0
b0b373b3-5eca-4aba-ab7e-9c21e34cd5b9	65584d58-1889-4d9b-a5b9-70c940c529d8	a889ca74-b784-43e1-90c0-5833b32898df	Disiplin	\N	0	0	0	1	\N	\N	0	0
b414c2ef-6e61-4a50-a786-2572ebc0ab67	65584d58-1889-4d9b-a5b9-70c940c529d8	d70c5578-b960-4272-9e36-01bfc68586d5	Kejujuran	\N	0	0	0	1	\N	\N	0	0
2a9ca9bb-aa7a-4165-93f0-389cd25c1276	65584d58-1889-4d9b-a5b9-70c940c529d8	47a4695a-8eca-4d21-8ae5-dee4e708794d	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
781f1378-d0b6-40b9-8466-565a4b082ea9	65584d58-1889-4d9b-a5b9-70c940c529d8	a91e2a00-a885-49d4-8ca0-b442b3b10dfd	Kerjasama	\N	0	0	0	1	\N	\N	0	0
b9b5f80e-4a0b-4804-8864-56638945bf56	65584d58-1889-4d9b-a5b9-70c940c529d8	8a748853-439a-49be-8dd8-26745b5e3bdb	Santun terhadap Pasien	\N	0	0	0	1	\N	\N	0	0
097eaa19-7160-4d2d-9af2-30d4500edb47	65584d58-1889-4d9b-a5b9-70c940c529d8	4314ce0c-e122-44fe-807b-00c5bbdb196a	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
9a34a297-7f86-4141-8e40-a2f7941f15f4	4962d0eb-eb2f-4205-ba63-fceaffdf21be	89d5f270-9bf7-43ce-a136-ea66e9cf168e	PEKERJAAN KLINIK	\N	0	0	0	1	\N	\N	0	1
d932c82b-3cd2-4e98-85e0-e8ffacee8444	4962d0eb-eb2f-4205-ba63-fceaffdf21be	52c00875-ff5b-40fa-bf03-2c57d786c6ec	PEKERJAAN KLINIK	\N	0	0	0	1	\N	\N	0	1
8580685c-9502-490a-8060-ea2c4fae6db5	4962d0eb-eb2f-4205-ba63-fceaffdf21be	b1bde434-acb3-4d0e-b5ea-f22e0b0940ef	Menerima dan membaca rujukan pemeriksaan  radiograf periapikal, melakukan informed consent pada pasien dan  menulis  pada  buku  catatan  di  ruang Xray	\N	2	0	0	1	\N	\N	0	0
08a187a0-e260-4bf3-9383-f4357ce9358c	4962d0eb-eb2f-4205-ba63-fceaffdf21be	8520b176-2b33-459f-bf63-97a3e153e45d	Informed Consent	\N	5	0	0	1	\N	\N	0	0
2d09a021-3b9a-4362-b8e2-ee829f532cba	4962d0eb-eb2f-4205-ba63-fceaffdf21be	e9fe4b01-3356-4836-9b40-b6e2c1f4e246	Mempersiapkan alat xray intraoral, memilih lama eksposur pada panel kontrol dan film yang akan digunakan	\N	2	0	0	1	\N	\N	0	0
ea020385-7494-4dea-a60d-2137ab030f5e	4962d0eb-eb2f-4205-ba63-fceaffdf21be	7236b2ff-217d-4998-9ef3-41b144e453f4	Proteksi Radiasi	\N	5	0	0	1	\N	\N	0	0
344cf463-b2d7-48cf-a835-79f112741f9a	4962d0eb-eb2f-4205-ba63-fceaffdf21be	326fef6b-1ae2-4248-89a4-991922cbb136	Posisi Pasien	\N	5	0	0	1	\N	\N	0	0
fafe41cf-2f90-406e-9bea-5eeaf49471a6	4962d0eb-eb2f-4205-ba63-fceaffdf21be	8db2983a-640f-4476-bf2f-82fbecefe22a	Mempersilahkan  pasien  untuk  masuk  dan\nmenjelaskan kepada pasien prosedur pemeriksaan radiologis menggunakan teknik periapikal bisektris	\N	5	0	0	1	\N	\N	0	0
28f7fa38-7f35-4732-903c-8746f233d847	4962d0eb-eb2f-4205-ba63-fceaffdf21be	f7f56eee-c3b2-4196-88fe-0b6ee19d17f4	Menggunakan Masker dan Sarung tangan	\N	2	0	0	1	\N	\N	0	0
73515fc0-bb88-43ae-8fcb-6c2a7972f95a	4962d0eb-eb2f-4205-ba63-fceaffdf21be	b9302baf-0246-4848-bc4c-16423150724b	Posisi Film	\N	5	0	0	1	\N	\N	0	0
b5920cea-c142-421f-bdf0-a21dacf0b7a1	4962d0eb-eb2f-4205-ba63-fceaffdf21be	3be73c17-b7d0-40b8-a16f-a64591c5a9e5	Pasien diinstruksikan untuk memakai apron pelindung radiasi	\N	3	0	0	1	\N	\N	0	0
38b3d964-1486-4d74-86b7-b777f1746170	4962d0eb-eb2f-4205-ba63-fceaffdf21be	169344ad-20af-4905-a2b5-7585fa61fb06	Posisi Tabung Xray	\N	5	0	0	1	\N	\N	0	0
96fe0923-a294-4e52-96e1-c97af999b888	4962d0eb-eb2f-4205-ba63-fceaffdf21be	457aae28-a96e-4450-a471-10ff880dccc5	Mempersilahkan pasien duduk di alat xray\ndan memposisikan kepala pasien: \na. Kepala bersandar pada headrest \nb. Bidang sagital tegak lurus lantai\nc. Bidang oklusal sejajar dengan lantai	\N	10	0	0	1	\N	\N	0	0
4d170401-bf11-4975-89f3-7980086a6c3c	4962d0eb-eb2f-4205-ba63-fceaffdf21be	cdcbb703-4912-4b17-9b7b-be748d7ae249	Instruksi Pasien	\N	5	0	0	1	\N	\N	0	0
962df9fe-7f22-4d53-9fe5-d52657d1bc13	4962d0eb-eb2f-4205-ba63-fceaffdf21be	40aa31de-c592-40b9-a2f0-99b45f6d0b94	Meletakkan film   intraoral kedalam mulut pasien, posisi objek yang akan diperiksa berada di  tengah film. Dot  film  berada  di insisal/oklusal gigi.	\N	5	0	0	1	\N	\N	0	0
8f31e863-a491-4620-a6f3-af0b04955154	4962d0eb-eb2f-4205-ba63-fceaffdf21be	ec8f5218-ecf9-461f-bbeb-2df2dad9285d	Exposure	\N	5	0	0	1	\N	\N	0	0
b3e04e55-59c5-4cfb-b51b-038e2f55f5f7	4962d0eb-eb2f-4205-ba63-fceaffdf21be	0168ed48-f471-4cc5-a9e0-d51cb5737ac1	Prosesing	\N	5	0	0	1	\N	\N	0	0
63c6748c-d49f-43ab-bce6-6b6caa426e04	4962d0eb-eb2f-4205-ba63-fceaffdf21be	5fdf51ed-449d-4e5f-a62f-4f9ed89e7c26	Jari pasien diarahkan untuk me-fiksasi film	\N	2	0	0	1	\N	\N	0	0
beebb045-1dd2-4b72-8219-a3aab4458796	4962d0eb-eb2f-4205-ba63-fceaffdf21be	26fb5ed1-f586-4805-b431-c73e532b850e	Mengatur Tabung eksposi pada:\na. Sudut vertikal disesuaikan objek yang akan diperiksa\nb. Sudut Horizontal disesuaikan objek yang akan diperiksa	\N	10	0	0	1	\N	\N	0	0
a5b00a5a-64fc-4454-89e4-fbbc66c90439	4962d0eb-eb2f-4205-ba63-fceaffdf21be	ab29848c-1713-44d0-8ae6-8ff7a15a7d5d	Mengarahkan tabung eksposi sesuai dengan titik penetrasi objek.	\N	5	0	0	1	\N	\N	0	0
8916d06e-e35b-45dd-a043-da6471bd2fe9	4962d0eb-eb2f-4205-ba63-fceaffdf21be	43f89f49-b5ff-47c6-8b41-f6532256ad31	Menginstruksikan pasien untuk tidak bergerak   dan   dan   menjelaskan   operator akan melakukan eksposi	\N	1	0	0	1	\N	\N	0	0
024b8aee-2d5b-4d87-a8e2-821e6d125a79	4962d0eb-eb2f-4205-ba63-fceaffdf21be	cffbd13b-a92e-46f6-a65a-208136261a11	Memencet tombol eksposi	\N	1	0	0	1	\N	\N	0	0
f23bfcee-ee34-4ec1-9e81-370ae61d41ca	4962d0eb-eb2f-4205-ba63-fceaffdf21be	8f9a5f01-1723-4f02-952a-45ffffd2b050	Mengeluarkan  fim  dari  mulut  pasien  dan mempersilahkan   pasien   berdiri,   melepas apron pelindung radiasi.	\N	1	0	0	1	\N	\N	0	0
eb17f6bc-899b-4d3b-9d4b-c70629a4eed8	4962d0eb-eb2f-4205-ba63-fceaffdf21be	666c4222-69c1-421b-8200-a10290440162	Mempersilahkan  pasien  kembali  ke  ruang tunggu untuk menunggu hasil radiograf.	\N	1	0	0	1	\N	\N	0	0
5d3a0678-1810-4ac6-8a85-f91c2321379c	4962d0eb-eb2f-4205-ba63-fceaffdf21be	c36494b4-8f30-4b6a-8020-84a37b4b80ca	SIKAP	\N	0	0	0	1	\N	\N	0	2
17eb3b33-2f4d-4616-b5f6-b70b7dd689cb	4962d0eb-eb2f-4205-ba63-fceaffdf21be	fbac69ca-23dc-454d-b77f-9777a32d7a5d	SIKAP	\N	0	0	0	1	\N	\N	0	2
1ec87d09-fe8a-451a-b1ac-2c977f0d9919	4962d0eb-eb2f-4205-ba63-fceaffdf21be	fe20ae99-30ce-4cea-a454-37359f16c3bd	Inisiatif	\N	0	0	0	1	\N	\N	0	0
cefb57d1-5679-499d-b1e6-8048a4c690df	4962d0eb-eb2f-4205-ba63-fceaffdf21be	b5d94bd4-dcfc-4602-9297-c00847852dea	Inisiatif	\N	0	0	0	1	\N	\N	0	0
cff2266e-c860-4443-8e13-c5ad563bd4ac	4962d0eb-eb2f-4205-ba63-fceaffdf21be	518e948d-dd5a-42a7-9cd8-df35a6510b88	Disiplin	\N	0	0	0	1	\N	\N	0	0
49418a3e-7404-4821-8187-adb573f1d61b	4962d0eb-eb2f-4205-ba63-fceaffdf21be	7eab875a-ad52-4ff2-971b-63e30724b03c	Disiplin	\N	0	0	0	1	\N	\N	0	0
233e1cc2-6340-4883-a4cc-61af97a27b9b	4962d0eb-eb2f-4205-ba63-fceaffdf21be	f603ceea-42c3-49a7-a9ab-0ee3227a2e72	Kejujuran	\N	0	0	0	1	\N	\N	0	0
0125a31c-f571-4fba-be9a-b9147a55bb08	4962d0eb-eb2f-4205-ba63-fceaffdf21be	af754f5e-cdef-4660-bc34-2bc09e06bc26	Kejujuran	\N	0	0	0	1	\N	\N	0	0
40267747-3d75-44b6-84b4-f0c4f841d402	4962d0eb-eb2f-4205-ba63-fceaffdf21be	6a89654c-909f-43e3-ab47-d39c30037418	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
b0592a4d-d158-4018-b8ec-902cac78702e	4962d0eb-eb2f-4205-ba63-fceaffdf21be	4009e0ce-7dc9-407e-be56-7292002c9f1f	Tanggung Jawab	\N	0	0	0	1	\N	\N	0	0
57c7f558-eadb-49f3-9321-49b2ed269a7f	4962d0eb-eb2f-4205-ba63-fceaffdf21be	e63c6735-4cde-4093-98cd-0b2822c924ce	Kerjasama	\N	0	0	0	1	\N	\N	0	0
e2228fbe-d317-4697-91bd-a8e5debc91df	4962d0eb-eb2f-4205-ba63-fceaffdf21be	24d7d73c-d5e9-4868-93b7-de9229b499a2	Kerjasama	\N	0	0	0	1	\N	\N	0	0
3da5399c-0e18-498c-9209-1fb237085e31	4962d0eb-eb2f-4205-ba63-fceaffdf21be	dc8f07b1-45cd-4977-8ce2-312f5455bf19	Santun terhadap Pasien	\N	0	0	0	1	\N	\N	0	0
0cec80e4-a3f6-4a64-b4da-a1c87bfe6e87	4962d0eb-eb2f-4205-ba63-fceaffdf21be	8c4c52d4-baf1-43d2-a6cb-cd62259bc6e7	Santun terhadap pasien	\N	0	0	0	1	\N	\N	0	0
02c703f5-a522-49ec-82bb-21cb9dbf80fb	4962d0eb-eb2f-4205-ba63-fceaffdf21be	a8e52691-7aa2-4ade-8323-e4e5495fb63b	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
639a6f85-28d9-41bb-90af-7acf309b9fcf	4962d0eb-eb2f-4205-ba63-fceaffdf21be	e9e25456-79dc-47b5-8e6d-5615706020ab	Santun terhadap dosen	\N	0	0	0	1	\N	\N	0	0
\.


--
-- TOC entry 3746 (class 0 OID 16629)
-- Dependencies: 258
-- Data for Name: type_three_trsdetailassesments; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.type_three_trsdetailassesments (id, trsassesmentid, assesmentdetailid, assesmentdescription, transactiondate, assesmentskala, assesmentbobotvalue, assesmentvalue, konditevalue, assesmentscore, active, created_at, updated_at, assementvalue, kodesub) FROM stdin;
125c3768-fbee-4091-8604-f313ef48828f	ec60fd17-2a42-44d0-a740-886527e68336	adb3f46d-afe5-45fe-8e6c-30bfb902cdef	Dasar/liner (10)	\N	10	0	\N	100	0	1	\N	\N	0	0
d8816414-73a6-4e08-b852-411a351d23f5	ec60fd17-2a42-44d0-a740-886527e68336	627eb09c-77e8-4d0a-a834-f7919bcb765b	Etsa,bonding (20)	\N	20	0	\N	100	0	1	\N	\N	0	0
96d46952-3441-4c73-bad6-40c61b03fe08	ec60fd17-2a42-44d0-a740-886527e68336	6d9652b3-dd85-4e94-b125-edac758a6d69	Penumpatan Komposit / Penumpatan Kompomer (25)	\N	25	0	\N	100	0	1	\N	\N	0	0
1c2c61c5-65fc-43cd-8dad-f9fe9b0cb47a	ec60fd17-2a42-44d0-a740-886527e68336	46369d9f-6283-4b33-9780-66aa11a87353	Kontrol/finishing/polishing (10)	\N	10	0	\N	100	0	1	\N	\N	0	0
5da418e4-9d25-451c-90d5-93a2c408275c	ec60fd17-2a42-44d0-a740-886527e68336	9abf651a-0bdb-40fe-a3f4-b7c756d20c68	Preparasi (35)	\N	35	0	\N	\N	0	1	\N	2024-04-05 09:59:25	0	0
8d804a4a-fbf3-43be-8fb4-5d5b0bea373a	9926c557-6ee3-4e8b-8bdf-e8d960a137bf	847bb26e-2bb2-435f-8b4e-c4371eeb803c	Indikasi (20)	\N	0	0	\N	0	0	1	\N	\N	0	1
7929e2be-751b-45fc-94a3-b7b36e66644b	9926c557-6ee3-4e8b-8bdf-e8d960a137bf	a7fc9ca2-652b-45e7-a2d3-a659fdf81a31	Indikasi (20)	\N	20	0	\N	100	0	1	\N	\N	0	0
0ad7278a-2bad-43aa-8389-58be34ca2927	9926c557-6ee3-4e8b-8bdf-e8d960a137bf	dc6f30ee-f1fe-4abb-98b0-5b0827d9245c	Pembersihan Gigi (25)	\N	0	0	\N	0	0	1	\N	\N	0	2
6e934bef-79b8-4971-b0b3-25f721ec636b	9926c557-6ee3-4e8b-8bdf-e8d960a137bf	40ce3881-d500-411f-a288-5dcf4f5b1435	a. Melakukan pembersihan gigi, sebelumnya diberikan disclosing solution	\N	10	0	\N	100	0	1	\N	\N	0	0
40dd9dfb-eb9b-4784-81b5-039b7f3a4df1	9926c557-6ee3-4e8b-8bdf-e8d960a137bf	377738f0-42e4-49f2-9f92-4cdffba4eadd	b. Melakukan pembuangan jaringan keras	\N	15	0	\N	100	0	1	\N	\N	0	0
336afd47-cea1-4018-ad79-a520444d4903	9926c557-6ee3-4e8b-8bdf-e8d960a137bf	db892c32-29ee-4e57-b260-88b1d3d559e4	Aplikasi (45)	\N	0	0	\N	0	0	1	\N	\N	0	3
183fb468-ea0f-4627-b918-0827aaa91f71	9926c557-6ee3-4e8b-8bdf-e8d960a137bf	9ddb2005-6de9-4747-a43f-ff198a3fdd40	a. Melakukan perawatan dengan bahan yang tepat	\N	35	0	\N	100	0	1	\N	\N	0	0
c5eaf619-7ab4-4daf-bf3e-700d433773d6	9926c557-6ee3-4e8b-8bdf-e8d960a137bf	dbd7e1ac-bdff-4cff-a916-719e3a44f8fb	b. Melakukan cek oklusi	\N	10	0	\N	100	0	1	\N	\N	0	0
f195b388-5420-4a48-a8be-8cea924ef6c4	9926c557-6ee3-4e8b-8bdf-e8d960a137bf	1beaaf81-93f7-4e15-9467-68437c653db2	Kontrol (10)	\N	0	0	\N	0	0	1	\N	\N	0	4
eae78058-f95e-4657-9bda-4e7b692333e1	9926c557-6ee3-4e8b-8bdf-e8d960a137bf	3003a9c7-16c0-4229-a42c-3e8f687fa720	Sempurna (utuh)	\N	10	0	\N	100	0	1	\N	\N	0	0
e402039b-e04b-4467-8e93-842af6ab70b8	27f5b271-b7f7-4681-b30b-c287484294cc	a0e62521-de01-4d8f-9b97-51fd13cda9e3	Pemeriksaan (18-30)	\N	0	0	\N	0	0	1	\N	\N	0	1
9b5a572e-cede-47ca-a555-e0af265804a7	27f5b271-b7f7-4681-b30b-c287484294cc	0eeab29b-b37f-4920-9577-89d258101a27	a. Informed consent	\N	5	0	\N	100	0	1	\N	\N	0	0
4763a915-d666-4d7e-8417-751a65634e7c	27f5b271-b7f7-4681-b30b-c287484294cc	0707607f-7cbf-4c8b-a09d-3d1f768bd719	b. Pengisian data pasien/ wawancara	\N	5	0	\N	100	0	1	\N	\N	0	0
9c6fbf10-5fd7-4b61-8b7a-cb4c306ed2a0	27f5b271-b7f7-4681-b30b-c287484294cc	09153e7c-3749-45fa-8e32-c63d4ab128f5	c. Pemeriksaan klinis ekstra oral	\N	5	0	\N	100	0	1	\N	\N	0	0
0809d1d5-5210-4469-a0b4-c2c8d5ede9af	27f5b271-b7f7-4681-b30b-c287484294cc	95f1006c-37fe-44a5-8b26-f85809a95470	d. Pemeriksaan intra oral (pemeriksaan klinis, radiografis)	\N	15	0	\N	100	0	1	\N	\N	0	0
3fd86cd5-53d6-499e-ac28-0e8a2f9265e1	27f5b271-b7f7-4681-b30b-c287484294cc	985e45b4-d027-4996-95b3-705a3062b1c2	Diagnosis (15-25)	\N	0	0	\N	0	0	1	\N	\N	0	2
e0baadda-b357-48ac-8b75-30dcc29b2d89	27f5b271-b7f7-4681-b30b-c287484294cc	3df888a8-1b4e-4f21-b0b6-b424ec9e43f2	Sesuai dengan hasil pemeriksaan	\N	25	0	\N	100	0	1	\N	\N	0	0
640979f0-318a-4e69-a7ca-f571d684c173	27f5b271-b7f7-4681-b30b-c287484294cc	be59a51d-6ade-434e-9348-e2f633c16f96	Sesuai dengan hasil pemeriksaan	\N	25	0	\N	100	0	1	\N	\N	0	0
4ee54dad-e0ab-4a47-a306-2426f7761916	27f5b271-b7f7-4681-b30b-c287484294cc	faede7a6-75fa-417b-ab23-9166c34d45fd	encana Perawatan (18-30)	\N	0	0	\N	0	0	1	\N	\N	0	3
b6cccc45-261f-4081-a9bb-ae1a4c5f92a3	27f5b271-b7f7-4681-b30b-c287484294cc	9c482226-0d3b-495f-b52f-19a761c0d368	enyelesaian (0-15)	\N	0	0	\N	0	0	1	\N	\N	0	4
6966e1d5-cc24-4b44-abe6-0bc39bb65c00	27f5b271-b7f7-4681-b30b-c287484294cc	db2f21ba-2b2a-44a2-9b17-80d231573c6d	a. Data rekam medik diselesaikan dalam 1 har	\N	15	0	\N	100	0	1	\N	\N	0	0
b853b51f-a4df-41d2-afb8-bb5cfd70994b	27f5b271-b7f7-4681-b30b-c287484294cc	7191eb27-3ba0-4c24-941c-636eb67ab97c	b. Data rekam medik diselesaikan >1 hari	\N	15	0	\N	100	0	1	\N	\N	0	0
c8276a4b-99d9-4e80-af06-29b7a4a18c5a	27f5b271-b7f7-4681-b30b-c287484294cc	c9c52dc4-a15d-4182-8d12-b3c3e2f4c2f6	c. Data rekam medik diselesaikan >1 mimggu	\N	15	0	\N	100	0	1	\N	\N	0	0
\.


--
-- TOC entry 3747 (class 0 OID 16639)
-- Dependencies: 260
-- Data for Name: universities; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.universities (id, name, active, created_at, updated_at) FROM stdin;
4dedaec1-4e5f-4492-9226-1e9af6aaf34b	UNIVERSITAS YARSI	1	\N	2024-02-22 13:24:14
\.


--
-- TOC entry 3748 (class 0 OID 16643)
-- Dependencies: 261
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.users (id, name, role, username, access_token, expired_at, email, email_verified_at, password, remember_token, created_at, updated_at) FROM stdin;
0e4b6492-62c4-4173-bd74-54ab0d79e084	FIQRI	admin	fiqri	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOi8vMjAyLjUxLjE5Ni45MS9hcGkvbG9naW4iLCJpYXQiOjE3MDkyNzU5NzQsImV4cCI6MTcwOTYzNTk3NCwibmJmIjoxNzA5Mjc1OTc0LCJqdGkiOiJKalh5bGxsNFptc0dGdzFlIiwic3ViIjoiMGU0YjY0OTItNjJjNC00MTczLWJkNzQtNTRhYjBkNzllMDg0IiwicHJ2IjoiMjNiZDVjODk0OWY2MDBhZGIzOWU3MDFjNDAwODcyZGI3YTU5NzZmNyJ9.FoJC_zDvJRy9LIvGEL22myIFvaVdhJQScQ9EUtxZgpI	2024-03-01 13:53:54	fiqri@rsyarsi.co.id	\N	$2y$10$97U/Z8Xm.3mmQjLrjMGSReSMRvESMcRt7VxjaxnbEmY4gjDHapCXy	\N	2024-02-13 09:30:19	2024-02-13 09:30:19
72fdd16a-190b-4a6e-9161-e2fc4f5dd895	alim	admin	alim	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOi8vMjAyLjUxLjE5Ni45MS9hcGkvbG9naW4iLCJpYXQiOjE3MDg1MjAwMzAsImV4cCI6MTcwODg4MDAzMCwibmJmIjoxNzA4NTIwMDMwLCJqdGkiOiJXYVA1YjhBak5oYWQyem1TIiwic3ViIjoiNzJmZGQxNmEtMTkwYi00YTZlLTkxNjEtZTJmYzRmNWRkODk1IiwicHJ2IjoiMjNiZDVjODk0OWY2MDBhZGIzOWU3MDFjNDAwODcyZGI3YTU5NzZmNyJ9.tafjVWhn-rvazB0lXQDV2eUMQBwQ3QrI_5wciYEopp8	2024-02-21 19:54:50	alim@rsyarsi.co.id	\N	$2y$10$NPPFCpMsZuOXoMVZEPO.1.nnKAXSr3RDJ5WFZiEXFc/Ah60w7Uew6	\N	2024-02-19 19:38:40	2024-02-19 19:38:40
ca7dcf76-59a6-4a44-aeeb-8824101544fa	Abdullah Fiqri	admin	1413000021	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOi8vMjAyLjUxLjE5Ni45MS9hcGkvbG9naW4iLCJpYXQiOjE3MDk5NTcxNjgsImV4cCI6MTcxMDMxNzE2OCwibmJmIjoxNzA5OTU3MTY4LCJqdGkiOiJlWDhEWE01S2d2NzlkMXNVIiwic3ViIjoiY2E3ZGNmNzYtNTlhNi00YTQ0LWFlZWItODgyNDEwMTU0NGZhIiwicHJ2IjoiMjNiZDVjODk0OWY2MDBhZGIzOWU3MDFjNDAwODcyZGI3YTU5NzZmNyJ9.-XzokvSPqSmOTlikAYTr3rAmJW_i80fSqaObXlxIgRE	2024-03-09 11:07:08	fiqri2@rsyarsi.co.id	\N	$2y$10$wmYmjkG3zQbCgvNF0FueOOO83WqA7UjXsU/TGfQT31gk7UOs9ys3y	\N	2024-02-23 14:51:10	2024-02-25 16:41:27
04c55019-4c0f-459f-bc9a-fc909c18d80d	drg. Hesti Witasari Jos Erry, Sp.KG	dosen	DY286	\N	\N	-	\N	$2y$10$sq8E7SjR1zJdjkd/zAqH8.n75Y4zC/he4cwt03hL1Fj3PCOmy2zie	\N	2024-03-20 15:16:47	2024-03-20 15:16:47
03fa1c17-beb9-4c3f-af39-4ab5549d8ffb	M Muchsin Abdillah	admin	muchsin	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxMjExMjg5NywiZXhwIjoxNzEyNDcyODk3LCJuYmYiOjE3MTIxMTI4OTcsImp0aSI6IlB5VlZUVzFhRmlVR29DelEiLCJzdWIiOiIwM2ZhMWMxNy1iZWI5LTRjM2YtYWYzOS00YWI1NTQ5ZDhmZmIiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.jAWPc7Ytvy1m_8FYKxlGcGGDbN7e3q_533B3TVMX_iI	2024-04-03 09:55:57	muchsian@rsyarsi.co.id	\N	$2y$10$DVl7KxXoqUJe2g70ddK8XOExkwt4ZX04KHP7VWNas58uJ/T6Aq1pa	\N	2024-02-22 13:22:39	2024-02-22 13:22:39
8ca580a4-f6c4-4b4c-99d6-d59fbd8ee783	drg. Vika Novia Zamri, Sp.Ort	dosen	D106	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxMzg1NzMyMywiZXhwIjoxNzE0MjE3MzIzLCJuYmYiOjE3MTM4NTczMjMsImp0aSI6IlhsbXBiTkdNZ254WHB3SFUiLCJzdWIiOiI4Y2E1ODBhNC1mNmM0LTRiNGMtOTlkNi1kNTlmYmQ4ZWU3ODMiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.h2f4kA2CJx3JLWgfR1Uz6lGquk4pVpr9OQqHYkA67Tg	2024-04-23 14:29:43	-	\N	$2y$10$WGIpDpSgU0NrHQ/O8gsiauZYmYULuu9dNfbBf2VpuLtWf159bRG8m	\N	2024-03-20 15:15:34	2024-03-20 15:15:34
85e0f895-7ecc-49ea-a9ee-faa347bde616	Laras Fajri Nanda Widiiswa	mahasiswa	4122023038	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjc5MTI3NiwiZXhwIjoxNzE3MTUxMjc2LCJuYmYiOjE3MTY3OTEyNzYsImp0aSI6Ik5NM0RsRGZwNjBOWVNObEQiLCJzdWIiOiI4NWUwZjg5NS03ZWNjLTQ5ZWEtYTllZS1mYWEzNDdiZGU2MTYiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.30zoXawY7eTV0MkyABby-1lFTAHX_61J_nV_2Ff_AWQ	2024-05-27 13:28:56	-	\N	$2y$10$XfcsTeRnpXXf5HZYaqaCVOhejyTTYENt49DFY3Hk9MhVSVTtr732C	\N	2024-03-27 10:39:51	2024-03-27 10:39:51
57c6595b-47e5-482d-b101-bc067c3cd01e	Andi Adjani Salwa Putri	mahasiswa	4122023026	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjg1OTgwMSwiZXhwIjoxNzE3MjE5ODAxLCJuYmYiOjE3MTY4NTk4MDEsImp0aSI6IkxYRUU3YUljYXlQVTdGU20iLCJzdWIiOiI1N2M2NTk1Yi00N2U1LTQ4MmQtYjEwMS1iYzA2N2MzY2QwMWUiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.bu3ih8OyzU44uDI8D_7mjZwxL660KM5MR6b7NRsxFTk	2024-05-28 08:31:01	-	\N	$2y$10$AIZtO3EBlcrxLr0m97T9duaO3nxXdNwcahmukG5DVAGq2oLzZp2CO	\N	2024-03-27 10:29:51	2024-03-27 10:29:51
e0793148-c08e-43c4-aac6-3ce587f3f6b7	Jihan Ar Rohim	mahasiswa	4122023035	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjg2MzA2NiwiZXhwIjoxNzE3MjIzMDY2LCJuYmYiOjE3MTY4NjMwNjYsImp0aSI6IkE1RUNoWXQ3Y1U2dzEyZUIiLCJzdWIiOiJlMDc5MzE0OC1jMDhlLTQzYzQtYWFjNi0zY2U1ODdmM2Y2YjciLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.jsiweVOSylQchJVVcBsRStAGkzUNX1YyP-hafF9Msfg	2024-05-28 09:25:26	-	\N	$2y$10$E2PhInpL3Y6t8CACf9reL.Mn0.xCAYtnxqghP917917b0tGWTeLEi	\N	2024-03-20 14:52:21	2024-03-20 14:52:21
9277030b-3c8b-4053-9185-cd5b6e48c477	Ivo Resky Primigo	mahasiswa	4122023033	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjg2NDcxNCwiZXhwIjoxNzE3MjI0NzE0LCJuYmYiOjE3MTY4NjQ3MTQsImp0aSI6ImV6UmRLZXE2bjZKQWdqdzciLCJzdWIiOiI5Mjc3MDMwYi0zYzhiLTQwNTMtOTE4NS1jZDViNmU0OGM0NzciLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.3gBijm2MA8SukEfSRUssunQQkQeP0y3w1PEj58aGZdM	2024-05-28 09:52:54	-	\N	$2y$10$Z3mgdBEu2EKUoFBvjF0yy.eA0uV7004LDGHr/xZ9Mno.D0LtomF9m	\N	2024-03-27 10:37:34	2024-03-27 10:37:34
86e81260-7b85-4f50-9f94-36339f563f7d	Putri Ayu Nurhadizah	mahasiswa	4122023040	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNTE1OTEyOSwiZXhwIjoxNzE1NTE5MTI5LCJuYmYiOjE3MTUxNTkxMjksImp0aSI6IktuZjZhU2lJd1JTcmNKZTIiLCJzdWIiOiI4NmU4MTI2MC03Yjg1LTRmNTAtOWY5NC0zNjMzOWY1NjNmN2QiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.QmhlcB_6pnJ7rPzvzLtAsCPzwe8tPrpFoQ64TWoPx4A	2024-05-08 16:06:29	-	\N	$2y$10$v9wNc26HWzy0vgTi8y6OIeCQcjchBmKQTCdV4MGkz/NXFcl8qvLo.	\N	2024-03-27 10:40:38	2024-03-27 10:40:38
5e5d88c5-35c5-4379-8c10-58708c3d593c	Cecelia Sandra Bayanudin	mahasiswa	4122023029	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjg2MDY0OSwiZXhwIjoxNzE3MjIwNjQ5LCJuYmYiOjE3MTY4NjA2NDksImp0aSI6IlQzZUtCWU5UY2hSSmMwNHIiLCJzdWIiOiI1ZTVkODhjNS0zNWM1LTQzNzktOGMxMC01ODcwOGMzZDU5M2MiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.-noOPNOqpG3ubrDAdexd2aS9bk9rKKzT_r9PmX_XX70	2024-05-28 08:45:09	-	\N	$2y$10$Y3X1CS4nsLR.Py1YW4QDNO85aAxpXL4QS3nCjB3dImP0hvJRtp1Za	\N	2024-03-27 10:35:27	2024-03-27 10:35:27
d0178ab1-8066-404a-812b-ff97816d2d2a	Karina Ivana Nariswari	mahasiswa	4122023036	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjg3MDMwOCwiZXhwIjoxNzE3MjMwMzA4LCJuYmYiOjE3MTY4NzAzMDgsImp0aSI6IjZDeGJtZ2dOTUY1V0MwbjIiLCJzdWIiOiJkMDE3OGFiMS04MDY2LTQwNGEtODEyYi1mZjk3ODE2ZDJkMmEiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.qDjiMzYIsqHoAPqdoZOGn5o51hK3tKbnIENqzyIycUE	2024-05-28 11:26:08	-	\N	$2y$10$jRpCv3NgrlLr24z5dj9YGOjEMpC49USjLPlgvDZ7gUDrgxRgi6F/.	\N	2024-03-27 10:38:22	2024-03-27 10:38:22
f67ddfa7-4ca9-44db-8c41-ca5d6717ad77	Hasbi	admin	hasbi	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxMjA0OTYwNCwiZXhwIjoxNzEyNDA5NjA0LCJuYmYiOjE3MTIwNDk2MDQsImp0aSI6IjVBS2NPdUhFTVpqT0ZsRFgiLCJzdWIiOiJmNjdkZGZhNy00Y2E5LTQ0ZGItOGM0MS1jYTVkNjcxN2FkNzciLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.Vh-A8Alzpte55jMayUVkE2FShwrbyAQ1kpiXBRyYFm8	2024-04-02 16:21:04	hasbi@rsyarsi.co.id	\N	$2y$10$I5JEPsUWQMvPzFGQiAOuD.zD7TRH.ycF0xXui.PsGy9MOuSloWM9O	\N	2024-02-22 14:52:08	2024-02-22 14:52:58
989e053a-baf7-44f3-9fda-93cb97712b75	drg. Selli Reviona	dosen	D014	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxMTUyMzI4NCwiZXhwIjoxNzExODgzMjg0LCJuYmYiOjE3MTE1MjMyODQsImp0aSI6IkExVVFYZTJJVzdoTWZHeFEiLCJzdWIiOiI5ODllMDUzYS1iYWY3LTQ0ZjMtOWZkYS05M2NiOTc3MTJiNzUiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.KyzAXiskjkqhnuO_CvxMvB83_ANg1BW-zzOdcC4mn6o	2024-03-27 14:09:04	-	\N	$2y$10$9Vo6JZzZJ7t4HPalHNDc7OGOTfmtwBvYx052Uu/BJ2qZlbARUN/t6	\N	2024-03-20 15:09:31	2024-03-20 15:09:31
0c9893da-d125-4d29-b8e8-18718fa6a9fb	drg. Dudik Winarko, Sp.KG	dosen	DY285	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxMjEyNTEwNCwiZXhwIjoxNzEyNDg1MTA0LCJuYmYiOjE3MTIxMjUxMDQsImp0aSI6IllKZ2l4QzRheGM3aG5rT1AiLCJzdWIiOiIwYzk4OTNkYS1kMTI1LTRkMjktYjhlOC0xODcxOGZhNmE5ZmIiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.yLHU2wW7A2XJCDlctiGJmC7JEmgD_jwu5AVrOLZQJ5Y	2024-04-03 13:19:24	-	\N	$2y$10$JZpB7mUt2uKC3KbGfFPvzeM2tElcZ2UAMf1iqXwOFIfMqR0Woauji	\N	2024-03-20 15:18:29	2024-03-20 15:18:29
cff74bde-29d1-4cfd-9751-35c748a5b1e6	drg. Bimo Rintoko, Sp.Pros	dosen	DY233	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxMjE5NDE5NSwiZXhwIjoxNzEyNTU0MTk1LCJuYmYiOjE3MTIxOTQxOTUsImp0aSI6IjgxU1JXVEFSM3lCdFlvOWQiLCJzdWIiOiJjZmY3NGJkZS0yOWQxLTRjZmQtOTc1MS0zNWM3NDhhNWIxZTYiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.XdFrzXCGBqQSXsSQcDo1Cihu4GqCCQQB4AFnMSk8xlw	2024-04-04 08:30:55	-	\N	$2y$10$McoPHzh1DlBB08hM4pIBouhZNv3HXnfNcMAGUiQq6Nx22acz0fe7W	\N	2024-03-20 15:13:12	2024-03-20 15:13:12
c07c239d-db89-45b0-8cc5-53c279b1ccd3	drg. Resky Mustafa,M. Kes.,Sp.RKG	dosen	DY296	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjg2ODA1OCwiZXhwIjoxNzE3MjI4MDU4LCJuYmYiOjE3MTY4NjgwNTgsImp0aSI6ImZmQUNmaW5HZjBWdlIyeVEiLCJzdWIiOiJjMDdjMjM5ZC1kYjg5LTQ1YjAtOGNjNS01M2MyNzliMWNjZDMiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.lQvkKM0_acpNITMdQmFNwCLGlYiahvkjSruuNNMDCOs	2024-05-28 10:48:38	-	\N	$2y$10$sGceSy8Xd.xwAqmtVDK8ZufVxDJn6XPimNlgYtVI.6j9qRCes.RAS	\N	2024-03-20 15:14:44	2024-03-20 15:14:44
cae2450a-d89a-4023-bcad-96ee8a112541	Faika Zahra Chairunnisa	mahasiswa	4122023030	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjc5MTIzNSwiZXhwIjoxNzE3MTUxMjM1LCJuYmYiOjE3MTY3OTEyMzUsImp0aSI6IlQ1UlVxZE41Wlg1WFh3UEsiLCJzdWIiOiJjYWUyNDUwYS1kODlhLTQwMjMtYmNhZC05NmVlOGExMTI1NDEiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.nDdgy_Fd0MkfnjCdT8Pb3GpPAu3URyezAfMImFpwWzw	2024-05-27 13:28:15	-	\N	$2y$10$6b4MwKNy1ZAFmnyi4bk3BuenEWVTw5.DA4UXT3Vs3xeAOG6mxtMp2	\N	2024-03-27 10:36:04	2024-03-27 10:36:04
e3cb0f53-6961-4660-8557-91b49f22e23e	BADER	admin	badrul	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNTE1ODk5MywiZXhwIjoxNzE1NTE4OTkzLCJuYmYiOjE3MTUxNTg5OTMsImp0aSI6IlBUd2kzQ2JyZHduWFM5YnMiLCJzdWIiOiJlM2NiMGY1My02OTYxLTQ2NjAtODU1Ny05MWI0OWYyMmUyM2UiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.HIOpZheB00oQVKxE--HaPi-p2eAFm1HdamZ-LWaIavw	2024-05-08 16:04:13	badrul@gmail.com	\N	$2y$10$trYEwbxMaT8Eh3VkJT6oUexc0G7wM4yVZLwpUIl0cLu6jLyZhVQmq	\N	2024-02-15 07:08:54	2024-02-20 19:46:29
22ef5c7c-acdd-4f28-8a1b-763a1798b3f0	Adila Hikmayanti	mahasiswa	4122023024	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjg5MTQ0NiwiZXhwIjoxNzE3MjUxNDQ2LCJuYmYiOjE3MTY4OTE0NDYsImp0aSI6IlgwTmNKZnRjSzdRT3NucDkiLCJzdWIiOiIyMmVmNWM3Yy1hY2RkLTRmMjgtOGExYi03NjNhMTc5OGIzZjAiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.2yAxHGkU32QNf-XkibQCx7bayd-1KinMxTxIkUdejjk	2024-05-28 17:18:26	-	\N	$2y$10$y32BbK9nf55DR.Wtc2dFi.AzT8vovQf8SyA5goO4P6pmGuUvCrENW	\N	2024-03-20 14:53:28	2024-03-20 14:53:28
4c84cd06-7dc9-4d17-a868-6c1513bd3150	drg. Yulia Rachma wijayanti, Sp.Perio,MM	dosen	DY177	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjY2MjA0OCwiZXhwIjoxNzE3MDIyMDQ4LCJuYmYiOjE3MTY2NjIwNDgsImp0aSI6ImwxdEFKWmxpTXh2SkdPeFkiLCJzdWIiOiI0Yzg0Y2QwNi03ZGM5LTRkMTctYTg2OC02YzE1MTNiZDMxNTAiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.kYqGir0GApwjPZG6E9a4_2gy_0mFVlcj2iCS-zZW5Q4	2024-05-26 01:35:08	-	\N	$2y$10$qM/cZvQDr/V.QijEhb8MlOQicstL9RaMyjdY0/qTpgIHo93j6gOMq	\N	2024-03-20 15:12:30	2024-03-20 15:12:30
a714cbf5-bcfd-4bf6-a62b-0ef96c7b6506	Farah Alifah Rahayu	mahasiswa	4122023031	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjc3NDIyMywiZXhwIjoxNzE3MTM0MjIzLCJuYmYiOjE3MTY3NzQyMjMsImp0aSI6Ind3YkFTbkRYMEFHQUpzNkEiLCJzdWIiOiJhNzE0Y2JmNS1iY2ZkLTRiZjYtYTYyYi0wZWY5NmM3YjY1MDYiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.rxQWdluGz9cMMCQeQQTt9qbSgjiGFw8JyGefwtAARfU	2024-05-27 08:44:43	-	\N	$2y$10$19LKY9aSvNHIPZtKCLTyqeJmOmmZcnK/l.WbG9tsVA2W2.AiHzMUq	\N	2024-03-27 10:36:42	2024-03-27 10:36:42
ae9de2a9-0ff7-45e5-8620-bacdf683f8c4	drg. Anugrah Prayudi Raharjo	dosen	D015	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjc4MDUyOSwiZXhwIjoxNzE3MTQwNTI5LCJuYmYiOjE3MTY3ODA1MjksImp0aSI6Ikx3OUloQ1FXck50MUNDWTciLCJzdWIiOiJhZTlkZTJhOS0wZmY3LTQ1ZTUtODYyMC1iYWNkZjY4M2Y4YzQiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.5N-2OejISXmz_pfwH0KH3OM_daGyvG057t65QnpLyB8	2024-05-27 10:29:49	-	\N	$2y$10$aiLjpTcCc8Hu9Me..18zx.t/6Rhyg3vUV//LraqoL19M0VX0sDvIa	\N	2024-03-20 15:08:58	2024-03-20 15:08:58
57959057-06f2-44b2-82d6-1163502839a5	Mutia Permata Putri	mahasiswa	4122023039	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjg2MDg2MiwiZXhwIjoxNzE3MjIwODYyLCJuYmYiOjE3MTY4NjA4NjIsImp0aSI6IlpCWlZENFM4TmlEV3R3WEUiLCJzdWIiOiI1Nzk1OTA1Ny0wNmYyLTQ0YjItODJkNi0xMTYzNTAyODM5YTUiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.YM7nIHrJ3kiJvrY7vuUNXYJ4fFoYjz6tlJAjLdAinYM	2024-05-28 08:48:42	-	\N	$2y$10$UMelWTYKxpcC.IY8Uj7i1O28uxTFmS9h9r1hCHZleXOspM7sA92ci	\N	2024-03-20 14:50:36	2024-03-20 14:50:36
9924710b-b664-45cd-93a6-17a7f2ecfbd4	Jessica Putri Souisa	mahasiswa	4122023034	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjk3MTg4NCwiZXhwIjoxNzE3MzMxODg0LCJuYmYiOjE3MTY5NzE4ODQsImp0aSI6Ilp6WHY4VjNvNDJPQ2xyNlEiLCJzdWIiOiI5OTI0NzEwYi1iNjY0LTQ1Y2QtOTNhNi0xN2E3ZjJlY2ZiZDQiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.YT35UmybuM2U3JvuxT7Vs_kO2vZxG52fhhsBQl_bcIM	2024-05-29 15:39:04	-	\N	$2y$10$Q/LX/cQiMt6vN4ov/G3JTOvTNcOoIm1K.ZZ/XdtqCABvnOp9T7FNy	\N	2024-03-20 14:51:50	2024-03-20 14:51:50
329b2055-838a-4723-89a6-5d7525ce5971	Atika Rahma Minabari	mahasiswa	4122023027	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjgwMjM4NywiZXhwIjoxNzE3MTYyMzg3LCJuYmYiOjE3MTY4MDIzODcsImp0aSI6IktPelByY0JrOERFeENGNUUiLCJzdWIiOiIzMjliMjA1NS04MzhhLTQ3MjMtODlhNi01ZDc1MjVjZTU5NzEiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.X5onyXJ1HQ-kmHkwuLuQln71sSM_TraCFmqb-ik4CBw	2024-05-27 16:34:07	-	\N	$2y$10$fp3/roLjT4DFUXgXwDHo7esxfjnx9EL0vHRcG4NRF5BEMDPJhPMBC	\N	2024-03-27 10:32:38	2024-03-27 10:32:38
631faa02-92f7-48c5-b7bb-0da0eee4093c	drg. Indira Chairulina Dara, Sp.KGA	dosen	DY284	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNzIxNTI0NCwiZXhwIjoxNzE3NTc1MjQ0LCJuYmYiOjE3MTcyMTUyNDQsImp0aSI6IjZDSXppdDlPcTVIb1JRaGIiLCJzdWIiOiI2MzFmYWEwMi05MmY3LTQ4YzUtYjdiYi0wZGEwZWVlNDA5M2MiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.KqhObz3WVkOql9LRCObz6jMfxLrF6T4d_j7B0oAKFOs	2024-06-01 11:15:04	-	\N	$2y$10$X6saL0qLszE95P99r9g.0uHuBROTu1SsSK2Vs9wofCRpNz43rRxxC	\N	2024-03-20 15:19:09	2024-03-20 15:19:09
08106bcf-46ac-49c6-99e9-274b3530f2b9	drg. Alongsyah,Sp.RKG.,Subsp.R.D.P (K)	dosen	DY287	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjc3OTMyMCwiZXhwIjoxNzE3MTM5MzIwLCJuYmYiOjE3MTY3NzkzMjAsImp0aSI6IkVYckRCS0l6WVBDVXRqcmYiLCJzdWIiOiIwODEwNmJjZi00NmFjLTQ5YzYtOTllOS0yNzRiMzUzMGYyYjkiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.6zIVTYGKD05lLU7X8Ss7KRUnWw3sN-v1392htz8_des	2024-05-27 10:09:40	-	\N	$2y$10$wV3QpPRcTbt2.D1qDfnyS.oXKbraGmg63xqfuyn0H8XUBQcs31vBW	\N	2024-03-20 15:13:57	2024-03-20 15:13:57
c051b700-37b8-47bd-9a96-0f1aaa973ff2	drg. Ufo Pramigi	dosen	DY169	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjM1NzMwNiwiZXhwIjoxNzE2NzE3MzA2LCJuYmYiOjE3MTYzNTczMDYsImp0aSI6InEzc1h1aE9kZGVtUUdFWkQiLCJzdWIiOiJjMDUxYjcwMC0zN2I4LTQ3YmQtOWE5Ni0wZjFhYWE5NzNmZjIiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.Vh8JLNdegSS4o0j92RCcgm7h3CWN5nAUsSx7W52HndI	2024-05-22 12:56:06	-	\N	$2y$10$rEr6UuoNACwslvkXiuCetuupBsgccLC6iOm.E.C1wpcmM1YB7essu	\N	2024-03-20 15:11:24	2024-03-20 15:11:24
cdbff537-68f2-4976-b22a-5681e6a0e321	Khairunnisa Nabiilah Putri	mahasiswa	4122023037	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjc4NTczMywiZXhwIjoxNzE3MTQ1NzMzLCJuYmYiOjE3MTY3ODU3MzMsImp0aSI6IktrMFFzZDVaS1VleENrR1oiLCJzdWIiOiJjZGJmZjUzNy02OGYyLTQ5NzYtYjIyYS01NjgxZTZhMGUzMjEiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.eo9sYl7J1bvK0mGHWBgmaMYA4l-BDgk2p-Rwj7Vymvc	2024-05-27 11:56:33	-	\N	$2y$10$DdkIklHIUUrjz7JMCUm89.hGOLejEPqsYRfo.ggkAG0F.6Lutq2d2	\N	2024-03-27 10:39:13	2024-03-27 10:39:13
14ac4b79-661e-4825-8415-16d085fe4095	Administrator	admin	admin	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjk1Njc2NiwiZXhwIjoxNzE3MzE2NzY2LCJuYmYiOjE3MTY5NTY3NjYsImp0aSI6IlpZQ3hpQ1FycUV5TjdJbm8iLCJzdWIiOiIxNGFjNGI3OS02NjFlLTQ4MjUtODQxNS0xNmQwODVmZTQwOTUiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.zslM5_8Ipv0kOOSdZjY_aN6PFO0q_jyZDVOLNa5vvgI	2024-05-29 11:27:06	admin@email.com	\N	$2y$10$QyVO7BkaYssdBQ96Oz/5sui4ZSgZpBrQaF3Xa8L0GWqlgfOL6CEt.	\N	2024-02-10 05:26:01	2024-02-21 19:46:03
c700bf63-087a-4dee-b9e7-712288aef5b8	Amalia Rafa Wulandari	mahasiswa	4122023025	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjc3MTM0MiwiZXhwIjoxNzE3MTMxMzQyLCJuYmYiOjE3MTY3NzEzNDIsImp0aSI6IkNiQVZab3Z1N2IwWlo4MEsiLCJzdWIiOiJjNzAwYmY2My0wODdhLTRkZWUtYjllNy03MTIyODhhZWY1YjgiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.7IpXZ7VJmdZp9YPbil-U2FUeJnZDyIHto64OQqslRR8	2024-05-27 07:56:42	-	\N	$2y$10$AxRR8acI1l97CgGSScVCXOiUu0Wy2RXzEy7HK07uh1j7VLnFLNh06	\N	2024-03-20 14:51:15	2024-03-20 14:51:15
91d5595c-982d-4b20-99e8-4b4fc96b56f1	drg. Chaira Musytaka Sukma, Sp.KG	dosen	DY172	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjg3NTYyNCwiZXhwIjoxNzE3MjM1NjI0LCJuYmYiOjE3MTY4NzU2MjQsImp0aSI6IjIwMjB3UkhFdHMzZmUwTjciLCJzdWIiOiI5MWQ1NTk1Yy05ODJkLTRiMjAtOTllOC00YjRmYzk2YjU2ZjEiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.NVt8Hnv168G7BEjabzMugKn1tiTQVyAurwO4ZwkxGbc	2024-05-28 12:54:44	-	\N	$2y$10$LxF/.GxgV8q6xeWn64nh7.GDEOrJFmA1EE.OZydu3iRHS0R4N9JGC	\N	2024-03-20 15:18:05	2024-03-20 15:18:05
3963be48-b56c-4bbb-951d-7380129e4666	Sahri Muhamad Risky	mahasiswa	4122023043	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjc4Mzk5NywiZXhwIjoxNzE3MTQzOTk3LCJuYmYiOjE3MTY3ODM5OTcsImp0aSI6IlRKRG04YTRSSXFVWVdiMGIiLCJzdWIiOiIzOTYzYmU0OC1iNTZjLTRiYmItOTUxZC03MzgwMTI5ZTQ2NjYiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.7zmlr3ZE1WwQBNILBMCUiIelsPwsHpoySJ209Oe_nF8	2024-05-27 11:27:37	-	\N	$2y$10$E90IputAhlxK3A7WU88Nd.Tflhl4qlvF22mHwr90cm2tUKz93Ivym	\N	2024-03-20 15:00:02	2024-03-20 15:00:02
02f81681-1b79-4ebc-8343-63497cae2513	Shabrina Ghisani M	mahasiswa	4122023045	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjg1NzIxMywiZXhwIjoxNzE3MjE3MjEzLCJuYmYiOjE3MTY4NTcyMTMsImp0aSI6InBUN0lpWm5IWFJjNE1JMmUiLCJzdWIiOiIwMmY4MTY4MS0xYjc5LTRlYmMtODM0My02MzQ5N2NhZTI1MTMiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.7A2gRY5HqPbemkHwfyfczPNver4-G3Yjsdgo0lCLQi8	2024-05-28 07:47:53	-	\N	$2y$10$9uRwbSsrgV21i.YDeP8nLOaERUQB8rXgfjVp1iHnPdu1JCEtOQEEu	\N	2024-03-20 14:59:20	2024-03-20 14:59:20
d2e5c81f-42ab-445a-8cd8-f8be8063a9c4	Qanita Regina Maharani	mahasiswa	4122023041	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjg2MjkxNiwiZXhwIjoxNzE3MjIyOTE2LCJuYmYiOjE3MTY4NjI5MTYsImp0aSI6ImJFM1JFSlplTnRudDZJeWciLCJzdWIiOiJkMmU1YzgxZi00MmFiLTQ0NWEtOGNkOC1mOGJlODA2M2E5YzQiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.qFs1Ek2-dYiGdAP2QMK0yK4ZYvV61betcVtLSXobkYs	2024-05-28 09:22:56	-	\N	$2y$10$Xi11KFlLIaRydI3V7m.UJeZanQT5DcNGhY1YrrnM3EirgfhJVXnFq	\N	2024-03-20 14:53:04	2024-03-20 14:53:04
aa995a2d-badd-4642-91f9-52a8d0ff6588	Rayyen Alfian Juneanro	mahasiswa	4122023042	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjg2MDU3NiwiZXhwIjoxNzE3MjIwNTc2LCJuYmYiOjE3MTY4NjA1NzYsImp0aSI6IlNvR09FNXREaTZDYlN3NmsiLCJzdWIiOiJhYTk5NWEyZC1iYWRkLTQ2NDItOTFmOS01MmE4ZDBmZjY1ODgiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.lPlsXzUAAo91Pr1IFQQw_FCbvDDEUdhmZMipv8YM7IQ	2024-05-28 08:43:56	-	\N	$2y$10$LGkm1FEYccDJulOGDJ9PKOsPgXLiIhcx8bAiZEBuP0QZ1gcZBKj6W	\N	2024-03-20 14:56:39	2024-03-20 14:56:39
8f4ad3cf-5f05-4331-ac61-757e6b09c691	Sekar Decita Ananda Iswanti	mahasiswa	4122023044	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjg3NTg0MCwiZXhwIjoxNzE3MjM1ODQwLCJuYmYiOjE3MTY4NzU4NDAsImp0aSI6IlQ1Yk16R2FhSVJabzNCRjIiLCJzdWIiOiI4ZjRhZDNjZi01ZjA1LTQzMzEtYWM2MS03NTdlNmIwOWM2OTEiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.Axcw_P9RMp2-SHqttSetn3guJ1PygShwXBH8KtshQwc	2024-05-28 12:58:20	-	\N	$2y$10$oQGFsi2Ihp3u391mWJaiqO1LDP5cRqlVarrOtQrKPZelr8Fh7bRca	\N	2024-03-27 10:41:35	2024-03-27 10:41:35
59422b10-8245-4165-bbaf-739a48d7b33b	Breaniza Dhari	mahasiswa	4122023028	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNjg2MDY3MywiZXhwIjoxNzE3MjIwNjczLCJuYmYiOjE3MTY4NjA2NzMsImp0aSI6InpRUGxWbHBVQmE4Z0lkVEEiLCJzdWIiOiI1OTQyMmIxMC04MjQ1LTQxNjUtYmJhZi03MzlhNDhkN2IzM2IiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.YnrDL6GRsY7lAb7w-30wDsYW-mZs1P63i9nQLhbGuh8	2024-05-28 08:45:33	-	\N	$2y$10$VefslIuC4hf1ysMxTSZoee/946Hnm6xLaUwwoEWeZR6Y0OC.9VhLe	\N	2024-03-27 10:33:27	2024-03-27 10:33:27
161fe372-52ed-4f29-adba-30855ab47d14	Ivan Hasan	mahasiswa	4122023032	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaXNpa21ma2cucnN5YXJzaS5jby5pZDo0NDMzL2FwaS9sb2dpbiIsImlhdCI6MTcxNzA3ODUyMywiZXhwIjoxNzE3NDM4NTIzLCJuYmYiOjE3MTcwNzg1MjMsImp0aSI6InlWS3VsZEJlbVRCV3NJOWIiLCJzdWIiOiIxNjFmZTM3Mi01MmVkLTRmMjktYWRiYS0zMDg1NWFiNDdkMTQiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.NqFISJ5g2WQrsbjk2mmRszBO8K3-6K-hfiqRH7bLZxI	2024-05-30 21:16:23	-	\N	$2y$10$zMkzFZbQj7ARzRAO410PletDz1.hr2u1ZlH4w7IZGAH847NNEjcTK	\N	2024-03-20 14:57:13	2024-03-20 14:57:13
\.


--
-- TOC entry 3749 (class 0 OID 16687)
-- Dependencies: 270
-- Data for Name: years; Type: TABLE DATA; Schema: public; Owner: rsyarsi
--

COPY public.years (id, name, active, created_at, updated_at) FROM stdin;
04f1c1a1-625a-4186-ac68-28e1e71c6777	2024	1	\N	\N
f70f6fbf-176f-4e19-9396-fec8c50dd62c	2023	1	\N	\N
\.


--
-- TOC entry 3772 (class 0 OID 0)
-- Dependencies: 231
-- Name: failed_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: rsyarsi
--

SELECT pg_catalog.setval('public.failed_jobs_id_seq', 1, false);


--
-- TOC entry 3773 (class 0 OID 0)
-- Dependencies: 240
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: rsyarsi
--

SELECT pg_catalog.setval('public.migrations_id_seq', 20, true);


--
-- TOC entry 3774 (class 0 OID 0)
-- Dependencies: 244
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: rsyarsi
--

SELECT pg_catalog.setval('public.personal_access_tokens_id_seq', 1, false);


--
-- TOC entry 3468 (class 2606 OID 16701)
-- Name: absencestudents absencestudents_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.absencestudents
    ADD CONSTRAINT absencestudents_pkey PRIMARY KEY (id);


--
-- TOC entry 3470 (class 2606 OID 16703)
-- Name: assesmentdetails assesmentdetails_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.assesmentdetails
    ADD CONSTRAINT assesmentdetails_pkey PRIMARY KEY (id);


--
-- TOC entry 3474 (class 2606 OID 16705)
-- Name: assesmentgroups assesmentgroups_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.assesmentgroups
    ADD CONSTRAINT assesmentgroups_pkey PRIMARY KEY (id);


--
-- TOC entry 3472 (class 2606 OID 16707)
-- Name: assesmentgroupfinals assesmentgroupsubs_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.assesmentgroupfinals
    ADD CONSTRAINT assesmentgroupsubs_pkey PRIMARY KEY (id);


--
-- TOC entry 3476 (class 2606 OID 16709)
-- Name: emrkonservasi_jobs emrkonservasi_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.emrkonservasi_jobs
    ADD CONSTRAINT emrkonservasi_jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 3478 (class 2606 OID 16711)
-- Name: emrkonservasis emrkonservasis_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.emrkonservasis
    ADD CONSTRAINT emrkonservasis_pkey PRIMARY KEY (id);


--
-- TOC entry 3480 (class 2606 OID 16713)
-- Name: emrortodonsies emrortodonsies_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.emrortodonsies
    ADD CONSTRAINT emrortodonsies_pkey PRIMARY KEY (id);


--
-- TOC entry 3482 (class 2606 OID 16715)
-- Name: emrpedodontie_behaviorratings emrpedodontie_behaviorratings_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.emrpedodontie_behaviorratings
    ADD CONSTRAINT emrpedodontie_behaviorratings_pkey PRIMARY KEY (id);


--
-- TOC entry 3490 (class 2606 OID 16717)
-- Name: emrperiodontie_soaps emrpedodontie_soaps_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.emrperiodontie_soaps
    ADD CONSTRAINT emrpedodontie_soaps_pkey PRIMARY KEY (id);


--
-- TOC entry 3484 (class 2606 OID 16719)
-- Name: emrpedodontie_treatmenplans emrpedodontie_treatmens_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.emrpedodontie_treatmenplans
    ADD CONSTRAINT emrpedodontie_treatmens_pkey PRIMARY KEY (id);


--
-- TOC entry 3486 (class 2606 OID 16721)
-- Name: emrpedodontie_treatmens emrpedodontie_treatmens_pkey1; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.emrpedodontie_treatmens
    ADD CONSTRAINT emrpedodontie_treatmens_pkey1 PRIMARY KEY (id);


--
-- TOC entry 3488 (class 2606 OID 16723)
-- Name: emrpedodonties emrpedodonties_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.emrpedodonties
    ADD CONSTRAINT emrpedodonties_pkey PRIMARY KEY (id);


--
-- TOC entry 3492 (class 2606 OID 16725)
-- Name: emrperiodonties emrperiodonties_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.emrperiodonties
    ADD CONSTRAINT emrperiodonties_pkey PRIMARY KEY (id);


--
-- TOC entry 3494 (class 2606 OID 16727)
-- Name: emrprostodontie_logbooks emrprostodontie_logbooks_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.emrprostodontie_logbooks
    ADD CONSTRAINT emrprostodontie_logbooks_pkey PRIMARY KEY (id);


--
-- TOC entry 3496 (class 2606 OID 16729)
-- Name: emrprostodonties emrprostodonties_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.emrprostodonties
    ADD CONSTRAINT emrprostodonties_pkey PRIMARY KEY (id);


--
-- TOC entry 3498 (class 2606 OID 16731)
-- Name: emrradiologies emrradiologies_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.emrradiologies
    ADD CONSTRAINT emrradiologies_pkey PRIMARY KEY (id);


--
-- TOC entry 3500 (class 2606 OID 16733)
-- Name: failed_jobs failed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 3502 (class 2606 OID 16735)
-- Name: failed_jobs failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- TOC entry 3504 (class 2606 OID 16737)
-- Name: finalassesment_konservasis finalassesment_konservasis_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.finalassesment_konservasis
    ADD CONSTRAINT finalassesment_konservasis_pkey PRIMARY KEY (uuid);


--
-- TOC entry 3506 (class 2606 OID 16739)
-- Name: finalassesment_orthodonties finalassesment_orthodonties_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.finalassesment_orthodonties
    ADD CONSTRAINT finalassesment_orthodonties_pkey PRIMARY KEY (id);


--
-- TOC entry 3508 (class 2606 OID 16741)
-- Name: finalassesment_periodonties finalassesment_periodonties_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.finalassesment_periodonties
    ADD CONSTRAINT finalassesment_periodonties_pkey PRIMARY KEY (id);


--
-- TOC entry 3510 (class 2606 OID 16743)
-- Name: finalassesment_prostodonties finalassesment_prostodonties_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.finalassesment_prostodonties
    ADD CONSTRAINT finalassesment_prostodonties_pkey PRIMARY KEY (id);


--
-- TOC entry 3512 (class 2606 OID 16745)
-- Name: finalassesment_radiologies finalassesment_radiologies_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.finalassesment_radiologies
    ADD CONSTRAINT finalassesment_radiologies_pkey PRIMARY KEY (uuid);


--
-- TOC entry 3514 (class 2606 OID 16747)
-- Name: hospitals hospitals_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.hospitals
    ADD CONSTRAINT hospitals_pkey PRIMARY KEY (id);


--
-- TOC entry 3516 (class 2606 OID 16749)
-- Name: lectures lectures_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.lectures
    ADD CONSTRAINT lectures_pkey PRIMARY KEY (id);


--
-- TOC entry 3518 (class 2606 OID 16751)
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 3521 (class 2606 OID 16753)
-- Name: patients patients_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_pkey PRIMARY KEY (noregistrasi);


--
-- TOC entry 3523 (class 2606 OID 16755)
-- Name: personal_access_tokens personal_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 3525 (class 2606 OID 16757)
-- Name: personal_access_tokens personal_access_tokens_token_unique; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_token_unique UNIQUE (token);


--
-- TOC entry 3528 (class 2606 OID 16759)
-- Name: semesters semesters_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.semesters
    ADD CONSTRAINT semesters_pkey PRIMARY KEY (id);


--
-- TOC entry 3530 (class 2606 OID 16761)
-- Name: specialistgroups specialistgroups_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.specialistgroups
    ADD CONSTRAINT specialistgroups_pkey PRIMARY KEY (id);


--
-- TOC entry 3532 (class 2606 OID 16763)
-- Name: specialists specialists_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.specialists
    ADD CONSTRAINT specialists_pkey PRIMARY KEY (id);


--
-- TOC entry 3534 (class 2606 OID 16765)
-- Name: students students_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (id);


--
-- TOC entry 3536 (class 2606 OID 16767)
-- Name: trsassesments trsassesments_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.trsassesments
    ADD CONSTRAINT trsassesments_pkey PRIMARY KEY (id);


--
-- TOC entry 3540 (class 2606 OID 16769)
-- Name: type_five_trsdetailassesments type_five_trsdetailassesments_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.type_five_trsdetailassesments
    ADD CONSTRAINT type_five_trsdetailassesments_pkey PRIMARY KEY (id);


--
-- TOC entry 3542 (class 2606 OID 16771)
-- Name: type_four_trsdetailassesments type_four_trsdetailassesments_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.type_four_trsdetailassesments
    ADD CONSTRAINT type_four_trsdetailassesments_pkey PRIMARY KEY (id);


--
-- TOC entry 3538 (class 2606 OID 16773)
-- Name: type_one_control_trsdetailassesments type_one_control_trsdetailassesments_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.type_one_control_trsdetailassesments
    ADD CONSTRAINT type_one_control_trsdetailassesments_pkey PRIMARY KEY (id);


--
-- TOC entry 3544 (class 2606 OID 16775)
-- Name: type_one_trsdetailassesments type_one_trsdetailassesments_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.type_one_trsdetailassesments
    ADD CONSTRAINT type_one_trsdetailassesments_pkey PRIMARY KEY (id);


--
-- TOC entry 3546 (class 2606 OID 16777)
-- Name: type_three_trsdetailassesments type_three_trsdetailassesments_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.type_three_trsdetailassesments
    ADD CONSTRAINT type_three_trsdetailassesments_pkey PRIMARY KEY (id);


--
-- TOC entry 3548 (class 2606 OID 16779)
-- Name: universities universities_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.universities
    ADD CONSTRAINT universities_pkey PRIMARY KEY (id);


--
-- TOC entry 3550 (class 2606 OID 16781)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 3552 (class 2606 OID 16783)
-- Name: years years_pkey; Type: CONSTRAINT; Schema: public; Owner: rsyarsi
--

ALTER TABLE ONLY public.years
    ADD CONSTRAINT years_pkey PRIMARY KEY (id);


--
-- TOC entry 3519 (class 1259 OID 16784)
-- Name: password_resets_email_index; Type: INDEX; Schema: public; Owner: rsyarsi
--

CREATE INDEX password_resets_email_index ON public.password_resets USING btree (email);


--
-- TOC entry 3526 (class 1259 OID 16785)
-- Name: personal_access_tokens_tokenable_type_tokenable_id_index; Type: INDEX; Schema: public; Owner: rsyarsi
--

CREATE INDEX personal_access_tokens_tokenable_type_tokenable_id_index ON public.personal_access_tokens USING btree (tokenable_type, tokenable_id);


-- Completed on 2024-06-02 15:28:24 WIB

--
-- PostgreSQL database dump complete
--

