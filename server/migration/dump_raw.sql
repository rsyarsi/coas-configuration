PGDMP                         |            rsyarsi_sikm     14.11 (Debian 14.11-1.pgdg120+2)    14.12 �    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    16384    rsyarsi_sikm    DATABASE     `   CREATE DATABASE rsyarsi_sikm WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.utf8';
    DROP DATABASE rsyarsi_sikm;
                rsyarsi    false                        3079    16385 	   tablefunc 	   EXTENSION     =   CREATE EXTENSION IF NOT EXISTS tablefunc WITH SCHEMA public;
    DROP EXTENSION tablefunc;
                   false            �           0    0    EXTENSION tablefunc    COMMENT     `   COMMENT ON EXTENSION tablefunc IS 'functions that manipulate whole tables, including crosstab';
                        false    2                        3079    16406 	   uuid-ossp 	   EXTENSION     ?   CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;
    DROP EXTENSION "uuid-ossp";
                   false            �           0    0    EXTENSION "uuid-ossp"    COMMENT     W   COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';
                        false    3            *           1255    16417 *   generatefinal_konservasi(uuid, uuid, uuid) 	   PROCEDURE     �  CREATE PROCEDURE public.generatefinal_konservasi(IN studentid uuid, IN semesterid uuid, IN yearid uuid)
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
 g   DROP PROCEDURE public.generatefinal_konservasi(IN studentid uuid, IN semesterid uuid, IN yearid uuid);
       public          rsyarsi    false            +           1255    16418 *   generatefinal_orthodonti(uuid, uuid, uuid) 	   PROCEDURE     �  CREATE PROCEDURE public.generatefinal_orthodonti(IN studentid uuid, IN semesterid uuid, IN yearid uuid)
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
 g   DROP PROCEDURE public.generatefinal_orthodonti(IN studentid uuid, IN semesterid uuid, IN yearid uuid);
       public          rsyarsi    false            4           1255    16420 ,   generatefinal_periodonties(uuid, uuid, uuid) 	   PROCEDURE       CREATE PROCEDURE public.generatefinal_periodonties(IN studentid uuid, IN semesterid uuid, IN yearid uuid)
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
 i   DROP PROCEDURE public.generatefinal_periodonties(IN studentid uuid, IN semesterid uuid, IN yearid uuid);
       public          rsyarsi    false            5           1255    16421 +   generatefinal_prostodonti(uuid, uuid, uuid) 	   PROCEDURE       CREATE PROCEDURE public.generatefinal_prostodonti(IN studentid uuid, IN semesterid uuid, IN yearid uuid)
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
 h   DROP PROCEDURE public.generatefinal_prostodonti(IN studentid uuid, IN semesterid uuid, IN yearid uuid);
       public          rsyarsi    false            6           1255    16422 )   generatefinal_radiologi(uuid, uuid, uuid) 	   PROCEDURE     �  CREATE PROCEDURE public.generatefinal_radiologi(IN studentid uuid, IN semesterid uuid, IN yearid uuid)
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
 f   DROP PROCEDURE public.generatefinal_radiologi(IN studentid uuid, IN semesterid uuid, IN yearid uuid);
       public          rsyarsi    false            �            1259    16423    absencestudents    TABLE     V  CREATE TABLE public.absencestudents (
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
 #   DROP TABLE public.absencestudents;
       public         heap    rsyarsi    false            �            1259    16426    assesmentdetails    TABLE     �  CREATE TABLE public.assesmentdetails (
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
 $   DROP TABLE public.assesmentdetails;
       public         heap    rsyarsi    false            �            1259    16433    assesmentgroupfinals    TABLE     �   CREATE TABLE public.assesmentgroupfinals (
    id uuid NOT NULL,
    name text,
    active integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    specialistid uuid,
    bobotvaluefinal numeric
);
 (   DROP TABLE public.assesmentgroupfinals;
       public         heap    rsyarsi    false            �            1259    16438    assesmentgroups    TABLE     �  CREATE TABLE public.assesmentgroups (
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
 #   DROP TABLE public.assesmentgroups;
       public         heap    rsyarsi    false            �            1259    16444    emrkonservasi_jobs    TABLE       CREATE TABLE public.emrkonservasi_jobs (
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
 &   DROP TABLE public.emrkonservasi_jobs;
       public         heap    rsyarsi    false            �            1259    16450    emrkonservasis    TABLE     �P  CREATE TABLE public.emrkonservasis (
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
 "   DROP TABLE public.emrkonservasis;
       public         heap    rsyarsi    false            �           0    0     COLUMN emrkonservasis.status_emr    COMMENT     Q   COMMENT ON COLUMN public.emrkonservasis.status_emr IS '[ OPEN, WRITE, FINISH ]';
          public          rsyarsi    false    221            �           0    0 &   COLUMN emrkonservasis.status_penilaian    COMMENT     W   COMMENT ON COLUMN public.emrkonservasis.status_penilaian IS '[ OPEN, WRITE, FINISH ]';
          public          rsyarsi    false    221            �            1259    16455    emrortodonsies    TABLE     �-  CREATE TABLE public.emrortodonsies (
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
 "   DROP TABLE public.emrortodonsies;
       public         heap    rsyarsi    false            �           0    0     COLUMN emrortodonsies.status_emr    COMMENT     Q   COMMENT ON COLUMN public.emrortodonsies.status_emr IS '[ OPEN, WRITE, FINISH ]';
          public          rsyarsi    false    222            �           0    0 &   COLUMN emrortodonsies.status_penilaian    COMMENT     W   COMMENT ON COLUMN public.emrortodonsies.status_penilaian IS '[ OPEN, WRITE, FINISH ]';
          public          rsyarsi    false    222            �            1259    16460    emrpedodontie_behaviorratings    TABLE     Q  CREATE TABLE public.emrpedodontie_behaviorratings (
    id uuid NOT NULL,
    emrid uuid NOT NULL,
    frankscale text NOT NULL,
    beforetreatment text NOT NULL,
    duringtreatment text NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    userentryname character varying(250)
);
 1   DROP TABLE public.emrpedodontie_behaviorratings;
       public         heap    rsyarsi    false            �            1259    16465    emrpedodontie_treatmenplans    TABLE     n  CREATE TABLE public.emrpedodontie_treatmenplans (
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
 /   DROP TABLE public.emrpedodontie_treatmenplans;
       public         heap    rsyarsi    false            �            1259    16470    emrpedodontie_treatmens    TABLE     �  CREATE TABLE public.emrpedodontie_treatmens (
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
 +   DROP TABLE public.emrpedodontie_treatmens;
       public         heap    rsyarsi    false            �            1259    16475    emrpedodonties    TABLE       CREATE TABLE public.emrpedodonties (
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
 "   DROP TABLE public.emrpedodonties;
       public         heap    rsyarsi    false            �           0    0     COLUMN emrpedodonties.status_emr    COMMENT     Q   COMMENT ON COLUMN public.emrpedodonties.status_emr IS '[ OPEN, WRITE, FINISH ]';
          public          rsyarsi    false    226            �           0    0 &   COLUMN emrpedodonties.status_penilaian    COMMENT     W   COMMENT ON COLUMN public.emrpedodonties.status_penilaian IS '[ OPEN, WRITE, FINISH ]';
          public          rsyarsi    false    226            �            1259    16480    emrperiodontie_soaps    TABLE       CREATE TABLE public.emrperiodontie_soaps (
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
 (   DROP TABLE public.emrperiodontie_soaps;
       public         heap    rsyarsi    false            �            1259    16486    emrperiodonties    TABLE     ��  CREATE TABLE public.emrperiodonties (
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
 #   DROP TABLE public.emrperiodonties;
       public         heap    rsyarsi    false            �           0    0 !   COLUMN emrperiodonties.status_emr    COMMENT     R   COMMENT ON COLUMN public.emrperiodonties.status_emr IS '[ OPEN, WRITE, FINISH ]';
          public          rsyarsi    false    228            �           0    0 '   COLUMN emrperiodonties.status_penilaian    COMMENT     X   COMMENT ON COLUMN public.emrperiodonties.status_penilaian IS '[ OPEN, WRITE, FINISH ]';
          public          rsyarsi    false    228            �            1259    16491    emrprostodontie_logbooks    TABLE     �  CREATE TABLE public.emrprostodontie_logbooks (
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
 ,   DROP TABLE public.emrprostodontie_logbooks;
       public         heap    rsyarsi    false            �            1259    16496    emrprostodonties    TABLE     �$  CREATE TABLE public.emrprostodonties (
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
 $   DROP TABLE public.emrprostodonties;
       public         heap    rsyarsi    false            �           0    0 "   COLUMN emrprostodonties.status_emr    COMMENT     S   COMMENT ON COLUMN public.emrprostodonties.status_emr IS '[ OPEN, WRITE, FINISH ]';
          public          rsyarsi    false    230            �           0    0 (   COLUMN emrprostodonties.status_penilaian    COMMENT     Y   COMMENT ON COLUMN public.emrprostodonties.status_penilaian IS '[ OPEN, WRITE, FINISH ]';
          public          rsyarsi    false    230            �            1259    16501    emrradiologies    TABLE     -  CREATE TABLE public.emrradiologies (
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
 "   DROP TABLE public.emrradiologies;
       public         heap    rsyarsi    false            �           0    0     COLUMN emrradiologies.status_emr    COMMENT     Q   COMMENT ON COLUMN public.emrradiologies.status_emr IS '[ OPEN, WRITE, FINISH ]';
          public          rsyarsi    false    231            �           0    0 &   COLUMN emrradiologies.status_penilaian    COMMENT     W   COMMENT ON COLUMN public.emrradiologies.status_penilaian IS '[ OPEN, WRITE, FINISH ]';
          public          rsyarsi    false    231            �            1259    16506    failed_jobs    TABLE     &  CREATE TABLE public.failed_jobs (
    id bigint NOT NULL,
    uuid character varying(255) NOT NULL,
    connection text NOT NULL,
    queue text NOT NULL,
    payload text NOT NULL,
    exception text NOT NULL,
    failed_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
    DROP TABLE public.failed_jobs;
       public         heap    rsyarsi    false            �            1259    16512    failed_jobs_id_seq    SEQUENCE     {   CREATE SEQUENCE public.failed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.failed_jobs_id_seq;
       public          rsyarsi    false    232            �           0    0    failed_jobs_id_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE public.failed_jobs_id_seq OWNED BY public.failed_jobs.id;
          public          rsyarsi    false    233            �            1259    16513    finalassesment_konservasis    TABLE       CREATE TABLE public.finalassesment_konservasis (
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
 .   DROP TABLE public.finalassesment_konservasis;
       public         heap    rsyarsi    false    3            �            1259    16519    finalassesment_orthodonties    TABLE     3  CREATE TABLE public.finalassesment_orthodonties (
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
 /   DROP TABLE public.finalassesment_orthodonties;
       public         heap    rsyarsi    false    3            �            1259    16525    finalassesment_periodonties    TABLE       CREATE TABLE public.finalassesment_periodonties (
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
 /   DROP TABLE public.finalassesment_periodonties;
       public         heap    rsyarsi    false    3            �            1259    16531    finalassesment_prostodonties    TABLE     �  CREATE TABLE public.finalassesment_prostodonties (
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
 0   DROP TABLE public.finalassesment_prostodonties;
       public         heap    rsyarsi    false    3            �            1259    16537    finalassesment_radiologies    TABLE     �  CREATE TABLE public.finalassesment_radiologies (
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
 .   DROP TABLE public.finalassesment_radiologies;
       public         heap    rsyarsi    false    3            �            1259    16543 	   hospitals    TABLE     �   CREATE TABLE public.hospitals (
    id uuid NOT NULL,
    name character varying(250) NOT NULL,
    active integer DEFAULT 1 NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);
    DROP TABLE public.hospitals;
       public         heap    rsyarsi    false            �            1259    16547    lectures    TABLE     ?  CREATE TABLE public.lectures (
    id uuid NOT NULL,
    specialistid uuid NOT NULL,
    name character varying(150) NOT NULL,
    doctotidsimrs integer NOT NULL,
    active integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    nim character varying(25)
);
    DROP TABLE public.lectures;
       public         heap    rsyarsi    false            �            1259    16550 
   migrations    TABLE     �   CREATE TABLE public.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);
    DROP TABLE public.migrations;
       public         heap    rsyarsi    false            �            1259    16553    migrations_id_seq    SEQUENCE     �   CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.migrations_id_seq;
       public          rsyarsi    false    241            �           0    0    migrations_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;
          public          rsyarsi    false    242            �            1259    16554    password_resets    TABLE     �   CREATE TABLE public.password_resets (
    email character varying(255) NOT NULL,
    token character varying(255) NOT NULL,
    created_at timestamp(0) without time zone
);
 #   DROP TABLE public.password_resets;
       public         heap    rsyarsi    false            �            1259    16559    patients    TABLE     d  CREATE TABLE public.patients (
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
    DROP TABLE public.patients;
       public         heap    rsyarsi    false            �            1259    16564    personal_access_tokens    TABLE     �  CREATE TABLE public.personal_access_tokens (
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
 *   DROP TABLE public.personal_access_tokens;
       public         heap    rsyarsi    false            �            1259    16569    personal_access_tokens_id_seq    SEQUENCE     �   CREATE SEQUENCE public.personal_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 4   DROP SEQUENCE public.personal_access_tokens_id_seq;
       public          rsyarsi    false    245            �           0    0    personal_access_tokens_id_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE public.personal_access_tokens_id_seq OWNED BY public.personal_access_tokens.id;
          public          rsyarsi    false    246            �            1259    16570 	   semesters    TABLE       CREATE TABLE public.semesters (
    id uuid NOT NULL,
    semestername character varying(15) NOT NULL,
    semestervalue integer NOT NULL,
    active integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);
    DROP TABLE public.semesters;
       public         heap    rsyarsi    false            �            1259    16573    specialistgroups    TABLE     �   CREATE TABLE public.specialistgroups (
    id uuid NOT NULL,
    name character varying(50) NOT NULL,
    active integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);
 $   DROP TABLE public.specialistgroups;
       public         heap    rsyarsi    false            �            1259    16576    specialists    TABLE     #  CREATE TABLE public.specialists (
    id uuid NOT NULL,
    specialistname character varying(150) NOT NULL,
    groupspecialistid uuid NOT NULL,
    active integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    simrsid integer
);
    DROP TABLE public.specialists;
       public         heap    rsyarsi    false            �            1259    16579    students    TABLE     �  CREATE TABLE public.students (
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
    DROP TABLE public.students;
       public         heap    rsyarsi    false            �            1259    16582    trsassesments    TABLE     �  CREATE TABLE public.trsassesments (
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
 !   DROP TABLE public.trsassesments;
       public         heap    rsyarsi    false            �            1259    16589 $   type_one_control_trsdetailassesments    TABLE     �  CREATE TABLE public.type_one_control_trsdetailassesments (
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
 8   DROP TABLE public.type_one_control_trsdetailassesments;
       public         heap    rsyarsi    false            �            1259    16594    trassesmentdetailtypeonecontrol    VIEW     �  CREATE VIEW public.trassesmentdetailtypeonecontrol AS
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
 2   DROP VIEW public.trassesmentdetailtypeonecontrol;
       public          rsyarsi    false    252    252    252    252    252    251    251    251    219    219    217    217    217    217    217    217    217    217    252    252            �            1259    16599    type_five_trsdetailassesments    TABLE     �  CREATE TABLE public.type_five_trsdetailassesments (
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
 1   DROP TABLE public.type_five_trsdetailassesments;
       public         heap    rsyarsi    false            �            1259    16604    trsassesmentdetailtypefive    VIEW     /  CREATE VIEW public.trsassesmentdetailtypefive AS
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
 -   DROP VIEW public.trsassesmentdetailtypefive;
       public          rsyarsi    false    254    217    217    217    217    217    217    217    217    219    254    254    254    219    219    251    251    251    254    254    254    254    254    254    254    254                        1259    16609    type_four_trsdetailassesments    TABLE     �  CREATE TABLE public.type_four_trsdetailassesments (
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
 1   DROP TABLE public.type_four_trsdetailassesments;
       public         heap    rsyarsi    false                       1259    16614    trsassesmentdetailtypefour    VIEW     �  CREATE VIEW public.trsassesmentdetailtypefour AS
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
 -   DROP VIEW public.trsassesmentdetailtypefour;
       public          rsyarsi    false    219    256    256    256    256    256    256    256    256    251    251    251    219    219    217    217    217    217    217    217    217    217                       1259    16619    type_one_trsdetailassesments    TABLE     �  CREATE TABLE public.type_one_trsdetailassesments (
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
 0   DROP TABLE public.type_one_trsdetailassesments;
       public         heap    rsyarsi    false                       1259    16624    trsassesmentdetailtypeone    VIEW     �  CREATE VIEW public.trsassesmentdetailtypeone AS
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
 ,   DROP VIEW public.trsassesmentdetailtypeone;
       public          rsyarsi    false    258    258    258    258    258    217    217    217    217    217    217    217    258    217    219    219    219    251    251    251    258    258                       1259    16629    type_three_trsdetailassesments    TABLE     ,  CREATE TABLE public.type_three_trsdetailassesments (
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
 2   DROP TABLE public.type_three_trsdetailassesments;
       public         heap    rsyarsi    false                       1259    16634    trsassesmentdetailtypethree    VIEW     6  CREATE VIEW public.trsassesmentdetailtypethree AS
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
 .   DROP VIEW public.trsassesmentdetailtypethree;
       public          rsyarsi    false    260    260    260    260    260    260    217    217    217    260    260    217    217    217    217    217    217    217    217    219    219    219    251    251    251                       1259    16639    universities    TABLE     �   CREATE TABLE public.universities (
    id uuid NOT NULL,
    name character varying(250) NOT NULL,
    active integer DEFAULT 1 NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);
     DROP TABLE public.universities;
       public         heap    rsyarsi    false                       1259    16643    users    TABLE       CREATE TABLE public.users (
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
    DROP TABLE public.users;
       public         heap    rsyarsi    false                       1259    16648    view_history_emrkonservasis    VIEW     �H  CREATE VIEW public.view_history_emrkonservasis AS
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
 .   DROP VIEW public.view_history_emrkonservasis;
       public          rsyarsi    false    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221    221            	           1259    16653    view_history_emrortodonsies    VIEW     )  CREATE VIEW public.view_history_emrortodonsies AS
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
 .   DROP VIEW public.view_history_emrortodonsies;
       public          rsyarsi    false    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222    222            
           1259    16658    view_history_emrpedodonties    VIEW     a  CREATE VIEW public.view_history_emrpedodonties AS
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
 .   DROP VIEW public.view_history_emrpedodonties;
       public          rsyarsi    false    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226    226                       1259    16663    view_history_emrperiodonties    VIEW     �~  CREATE VIEW public.view_history_emrperiodonties AS
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
 /   DROP VIEW public.view_history_emrperiodonties;
       public          rsyarsi    false    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228    228                       1259    16668    view_history_emrprostodonties    VIEW     i!  CREATE VIEW public.view_history_emrprostodonties AS
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
 0   DROP VIEW public.view_history_emrprostodonties;
       public          rsyarsi    false    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230                       1259    16673    view_history_emrradiologies    VIEW     �  CREATE VIEW public.view_history_emrradiologies AS
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
 .   DROP VIEW public.view_history_emrradiologies;
       public          rsyarsi    false    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231    231                       1259    16678    viewabsencemonthreport    VIEW     �   CREATE VIEW public.viewabsencemonthreport AS
 SELECT a.id,
    a.studentid,
    b.name,
    a.time_in,
    a.time_out,
    a.periode,
    b.nim
   FROM (public.absencestudents a
     JOIN public.students b ON ((a.studentid = b.id)));
 )   DROP VIEW public.viewabsencemonthreport;
       public          rsyarsi    false    216    216    216    250    250    250    216    216                       1259    16682    viewassesmentdetailbygrouptypes    VIEW     �  CREATE VIEW public.viewassesmentdetailbygrouptypes AS
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
 2   DROP VIEW public.viewassesmentdetailbygrouptypes;
       public          rsyarsi    false    217    219    219    219    219    249    249    217    217    217    217    217    217    217    217    217    217    217    217                       1259    16687    years    TABLE     �   CREATE TABLE public.years (
    id uuid NOT NULL,
    name character varying(4) NOT NULL,
    active integer DEFAULT 1 NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);
    DROP TABLE public.years;
       public         heap    rsyarsi    false                       1259    16691    viewtrsassesmentheader    VIEW     :  CREATE VIEW public.viewtrsassesmentheader AS
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
 )   DROP VIEW public.viewtrsassesmentheader;
       public          rsyarsi    false    250    272    272    251    251    251    251    251    251    251    251    251    251    251    251    251    251    250    250    249    249    247    247    240    240    219    219            �           2604    16696    failed_jobs id    DEFAULT     p   ALTER TABLE ONLY public.failed_jobs ALTER COLUMN id SET DEFAULT nextval('public.failed_jobs_id_seq'::regclass);
 =   ALTER TABLE public.failed_jobs ALTER COLUMN id DROP DEFAULT;
       public          rsyarsi    false    233    232            �           2604    16697    migrations id    DEFAULT     n   ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);
 <   ALTER TABLE public.migrations ALTER COLUMN id DROP DEFAULT;
       public          rsyarsi    false    242    241            �           2604    16698    personal_access_tokens id    DEFAULT     �   ALTER TABLE ONLY public.personal_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.personal_access_tokens_id_seq'::regclass);
 H   ALTER TABLE public.personal_access_tokens ALTER COLUMN id DROP DEFAULT;
       public          rsyarsi    false    246    245            |          0    16423    absencestudents 
   TABLE DATA           �   COPY public.absencestudents (id, studentid, time_in, time_out, date, statusabsensi, updated_at, created_at, periode) FROM stdin;
    public          rsyarsi    false    216   ;�      }          0    16426    assesmentdetails 
   TABLE DATA           |  COPY public.assesmentdetails (id, assesmentgroupid, assesmentnumbers, assesmentdescription, assesmentbobotvalue, assesmentskalavalue, assesmentskalavaluestart, assesmentskalavalueend, assesmentkonditevalue, assesmentkonditevaluestart, assesmentkonditevalueend, active, created_at, updated_at, assesmentvaluestart, assesmentvalueend, kodesub, index_sub, kode_sub_name) FROM stdin;
    public          rsyarsi    false    217   �      ~          0    16433    assesmentgroupfinals 
   TABLE DATA           w   COPY public.assesmentgroupfinals (id, name, active, created_at, updated_at, specialistid, bobotvaluefinal) FROM stdin;
    public          rsyarsi    false    218   %                0    16438    assesmentgroups 
   TABLE DATA           �   COPY public.assesmentgroups (id, specialistid, assementgroupname, type, active, created_at, updated_at, valuetotal, isskala, idassesmentgroupfinal, bobotprosenfinal) FROM stdin;
    public          rsyarsi    false    219   �(      �          0    16444    emrkonservasi_jobs 
   TABLE DATA           �   COPY public.emrkonservasi_jobs (id, datejob, keadaangigi, tindakan, keterangan, user_entry, user_entry_name, user_verify, user_verify_name, created_at, updated_at, idemr, active, date_verify) FROM stdin;
    public          rsyarsi    false    220   �3      �          0    16450    emrkonservasis 
   TABLE DATA           2  COPY public.emrkonservasis (id, noregister, noepisode, nomorrekammedik, tanggal, namapasien, pekerjaan, jeniskelamin, alamatpasien, nomortelpon, namaoperator, nim, sblmperawatanpemeriksaangigi_18_tv, sblmperawatanpemeriksaangigi_17_tv, sblmperawatanpemeriksaangigi_16_tv, sblmperawatanpemeriksaangigi_15_55_tv, sblmperawatanpemeriksaangigi_14_54_tv, sblmperawatanpemeriksaangigi_13_53_tv, sblmperawatanpemeriksaangigi_12_52_tv, sblmperawatanpemeriksaangigi_11_51_tv, sblmperawatanpemeriksaangigi_21_61_tv, sblmperawatanpemeriksaangigi_22_62_tv, sblmperawatanpemeriksaangigi_23_63_tv, sblmperawatanpemeriksaangigi_24_64_tv, sblmperawatanpemeriksaangigi_25_65_tv, sblmperawatanpemeriksaangigi_26_tv, sblmperawatanpemeriksaangigi_27_tv, sblmperawatanpemeriksaangigi_28_tv, sblmperawatanpemeriksaangigi_18_diagnosis, sblmperawatanpemeriksaangigi_17_diagnosis, sblmperawatanpemeriksaangigi_16_diagnosis, sblmperawatanpemeriksaangigi_15_55_diagnosis, sblmperawatanpemeriksaangigi_14_54_diagnosis, sblmperawatanpemeriksaangigi_13_53_diagnosis, sblmperawatanpemeriksaangigi_12_52_diagnosis, sblmperawatanpemeriksaangigi_11_51_diagnosis, sblmperawatanpemeriksaangigi_21_61_diagnosis, sblmperawatanpemeriksaangigi_22_62_diagnosis, sblmperawatanpemeriksaangigi_23_63_diagnosis, sblmperawatanpemeriksaangigi_24_64_diagnosis, sblmperawatanpemeriksaangigi_25_65_diagnosis, sblmperawatanpemeriksaangigi_26_diagnosis, sblmperawatanpemeriksaangigi_27_diagnosis, sblmperawatanpemeriksaangigi_28_diagnosis, sblmperawatanpemeriksaangigi_18_rencanaperawatan, sblmperawatanpemeriksaangigi_17_rencanaperawatan, sblmperawatanpemeriksaangigi_16_rencanaperawatan, sblmperawatanpemeriksaangigi_15_55_rencanaperawatan, sblmperawatanpemeriksaangigi_14_54_rencanaperawatan, sblmperawatanpemeriksaangigi_13_53_rencanaperawatan, sblmperawatanpemeriksaangigi_12_52_rencanaperawatan, sblmperawatanpemeriksaangigi_11_51_rencanaperawatan, sblmperawatanpemeriksaangigi_21_61_rencanaperawatan, sblmperawatanpemeriksaangigi_22_62_rencanaperawatan, sblmperawatanpemeriksaangigi_23_63_rencanaperawatan, sblmperawatanpemeriksaangigi_24_64_rencanaperawatan, sblmperawatanpemeriksaangigi_25_65_rencanaperawatan, sblmperawatanpemeriksaangigi_26_rencanaperawatan, sblmperawatanpemeriksaangigi_27_rencanaperawatan, sblmperawatanpemeriksaangigi_28_rencanaperawatan, sblmperawatanpemeriksaangigi_41_81_tv, sblmperawatanpemeriksaangigi_42_82_tv, sblmperawatanpemeriksaangigi_43_83_tv, sblmperawatanpemeriksaangigi_44_84_tv, sblmperawatanpemeriksaangigi_45_85_tv, sblmperawatanpemeriksaangigi_46_tv, sblmperawatanpemeriksaangigi_47_tv, sblmperawatanpemeriksaangigi_48_tv, sblmperawatanpemeriksaangigi_38_tv, sblmperawatanpemeriksaangigi_37_tv, sblmperawatanpemeriksaangigi_36_tv, sblmperawatanpemeriksaangigi_35_75_tv, sblmperawatanpemeriksaangigi_34_74_tv, sblmperawatanpemeriksaangigi_33_73_tv, sblmperawatanpemeriksaangigi_32_72_tv, sblmperawatanpemeriksaangigi_31_71_tv, sblmperawatanpemeriksaangigi_41_81_diagnosis, sblmperawatanpemeriksaangigi_42_82_diagnosis, sblmperawatanpemeriksaangigi_43_83_diagnosis, sblmperawatanpemeriksaangigi_44_84_diagnosis, sblmperawatanpemeriksaangigi_45_85_diagnosis, sblmperawatanpemeriksaangigi_46_diagnosis, sblmperawatanpemeriksaangigi_47_diagnosis, sblmperawatanpemeriksaangigi_48_diagnosis, sblmperawatanpemeriksaangigi_38_diagnosis, sblmperawatanpemeriksaangigi_37_diagnosis, sblmperawatanpemeriksaangigi_36_diagnosis, sblmperawatanpemeriksaangigi_35_75_diagnosis, sblmperawatanpemeriksaangigi_34_74_diagnosis, sblmperawatanpemeriksaangigi_33_73_diagnosis, sblmperawatanpemeriksaangigi_32_72_diagnosis, sblmperawatanpemeriksaangigi_31_71_diagnosis, sblmperawatanpemeriksaangigi_41_81_rencanaperawatan, sblmperawatanpemeriksaangigi_42_82_rencanaperawatan, sblmperawatanpemeriksaangigi_43_83_rencanaperawatan, sblmperawatanpemeriksaangigi_44_84_rencanaperawatan, sblmperawatanpemeriksaangigi_45_85_rencanaperawatan, sblmperawatanpemeriksaangigi_46_rencanaperawatan, sblmperawatanpemeriksaangigi_47_rencanaperawatan, sblmperawatanpemeriksaangigi_48_rencanaperawatan, sblmperawatanpemeriksaangigi_38_rencanaperawatan, sblmperawatanpemeriksaangigi_37_rencanaperawatan, sblmperawatanpemeriksaangigi_36_rencanaperawatan, sblmperawatanpemeriksaangigi_35_75_rencanaperawatan, sblmperawatanpemeriksaangigi_34_74_rencanaperawatan, sblmperawatanpemeriksaangigi_33_73_rencanaperawatan, sblmperawatanpemeriksaangigi_32_72_rencanaperawatan, sblmperawatanpemeriksaangigi_31_71_rencanaperawatan, ssdhperawatanpemeriksaangigi_18_tv, ssdhperawatanpemeriksaangigi_17_tv, ssdhperawatanpemeriksaangigi_16_tv, ssdhperawatanpemeriksaangigi_15_55_tv, ssdhperawatanpemeriksaangigi_14_54_tv, ssdhperawatanpemeriksaangigi_13_53_tv, ssdhperawatanpemeriksaangigi_12_52_tv, ssdhperawatanpemeriksaangigi_11_51_tv, ssdhperawatanpemeriksaangigi_21_61_tv, ssdhperawatanpemeriksaangigi_22_62_tv, ssdhperawatanpemeriksaangigi_23_63_tv, ssdhperawatanpemeriksaangigi_24_64_tv, ssdhperawatanpemeriksaangigi_25_65_tv, ssdhperawatanpemeriksaangigi_26_tv, ssdhperawatanpemeriksaangigi_27_tv, ssdhperawatanpemeriksaangigi_28_tv, ssdhperawatanpemeriksaangigi_18_diagnosis, ssdhperawatanpemeriksaangigi_17_diagnosis, ssdhperawatanpemeriksaangigi_16_diagnosis, ssdhperawatanpemeriksaangigi_15_55_diagnosis, ssdhperawatanpemeriksaangigi_14_54_diagnosis, ssdhperawatanpemeriksaangigi_13_53_diagnosis, ssdhperawatanpemeriksaangigi_12_52_diagnosis, ssdhperawatanpemeriksaangigi_11_51_diagnosis, ssdhperawatanpemeriksaangigi_21_61_diagnosis, ssdhperawatanpemeriksaangigi_22_62_diagnosis, ssdhperawatanpemeriksaangigi_23_63_diagnosis, ssdhperawatanpemeriksaangigi_24_64_diagnosis, ssdhperawatanpemeriksaangigi_25_65_diagnosis, ssdhperawatanpemeriksaangigi_26_diagnosis, ssdhperawatanpemeriksaangigi_27_diagnosis, ssdhperawatanpemeriksaangigi_28_diagnosis, ssdhperawatanpemeriksaangigi_18_rencanaperawatan, ssdhperawatanpemeriksaangigi_17_rencanaperawatan, ssdhperawatanpemeriksaangigi_16_rencanaperawatan, ssdhperawatanpemeriksaangigi_15_55_rencanaperawatan, ssdhperawatanpemeriksaangigi_14_54_rencanaperawatan, ssdhperawatanpemeriksaangigi_13_53_rencanaperawatan, ssdhperawatanpemeriksaangigi_12_52_rencanaperawatan, ssdhperawatanpemeriksaangigi_11_51_rencanaperawatan, ssdhperawatanpemeriksaangigi_21_61_rencanaperawatan, ssdhperawatanpemeriksaangigi_22_62_rencanaperawatan, ssdhperawatanpemeriksaangigi_23_63_rencanaperawatan, ssdhperawatanpemeriksaangigi_24_64_rencanaperawatan, ssdhperawatanpemeriksaangigi_25_65_rencanaperawatan, ssdhperawatanpemeriksaangigi_26_rencanaperawatan, ssdhperawatanpemeriksaangigi_27_rencanaperawatan, ssdhperawatanpemeriksaangigi_28_rencanaperawatan, ssdhperawatanpemeriksaangigi_41_81_tv, ssdhperawatanpemeriksaangigi_42_82_tv, ssdhperawatanpemeriksaangigi_43_83_tv, ssdhperawatanpemeriksaangigi_44_84_tv, ssdhperawatanpemeriksaangigi_45_85_tv, ssdhperawatanpemeriksaangigi_46_tv, ssdhperawatanpemeriksaangigi_47_tv, ssdhperawatanpemeriksaangigi_48_tv, ssdhperawatanpemeriksaangigi_38_tv, ssdhperawatanpemeriksaangigi_37_tv, ssdhperawatanpemeriksaangigi_36_tv, ssdhperawatanpemeriksaangigi_35_75_tv, ssdhperawatanpemeriksaangigi_34_74_tv, ssdhperawatanpemeriksaangigi_33_73_tv, ssdhperawatanpemeriksaangigi_32_72_tv, ssdhperawatanpemeriksaangigi_31_71_tv, ssdhperawatanpemeriksaangigi_41_81_diagnosis, ssdhperawatanpemeriksaangigi_42_82_diagnosis, ssdhperawatanpemeriksaangigi_43_83_diagnosis, ssdhperawatanpemeriksaangigi_44_84_diagnosis, ssdhperawatanpemeriksaangigi_45_85_diagnosis, ssdhperawatanpemeriksaangigi_46_diagnosis, ssdhperawatanpemeriksaangigi_47_diagnosis, ssdhperawatanpemeriksaangigi_48_diagnosis, ssdhperawatanpemeriksaangigi_38_diagnosis, ssdhperawatanpemeriksaangigi_37_diagnosis, ssdhperawatanpemeriksaangigi_36_diagnosis, ssdhperawatanpemeriksaangigi_35_75_diagnosis, ssdhperawatanpemeriksaangigi_34_74_diagnosis, ssdhperawatanpemeriksaangigi_33_73_diagnosis, ssdhperawatanpemeriksaangigi_32_72_diagnosis, ssdhperawatanpemeriksaangigi_31_71_diagnosis, ssdhperawatanpemeriksaangigi_41_81_rencanaperawatan, ssdhperawatanpemeriksaangigi_42_82_rencanaperawatan, ssdhperawatanpemeriksaangigi_43_83_rencanaperawatan, ssdhperawatanpemeriksaangigi_44_84_rencanaperawatan, ssdhperawatanpemeriksaangigi_45_85_rencanaperawatan, ssdhperawatanpemeriksaangigi_46_rencanaperawatan, ssdhperawatanpemeriksaangigi_47_rencanaperawatan, ssdhperawatanpemeriksaangigi_48_rencanaperawatan, ssdhperawatanpemeriksaangigi_38_rencanaperawatan, ssdhperawatanpemeriksaangigi_37_rencanaperawatan, ssdhperawatanpemeriksaangigi_36_rencanaperawatan, ssdhperawatanpemeriksaangigi_35_75_rencanaperawatan, ssdhperawatanpemeriksaangigi_34_74_rencanaperawatan, ssdhperawatanpemeriksaangigi_33_73_rencanaperawatan, ssdhperawatanpemeriksaangigi_32_72_rencanaperawatan, ssdhperawatanpemeriksaangigi_31_71_rencanaperawatan, sblmperawatanfaktorrisikokaries_sikap, sblmperawatanfaktorrisikokaries_status, sblmperawatanfaktorrisikokaries_saliva_tanpastimulasi_hidrasi, sblmperawatanfaktorrisikokaries_saliva_tanpastimulasi_viskosita, "sblmperawatanfaktorrisikokaries_saliva_tanpastimulasi_pH", sblmperawatanfaktorrisikokaries_saliva_denganstimulasi_hidrasi, sblmperawatanfaktorrisikokaries_saliva_denganstimulasi_kecepata, sblmperawatanfaktorrisikokaries_saliva_denganstimulasi_kapasita, "sblmperawatanfaktorrisikokaries_saliva_denganstimulasi_pH", "sblmperawatanfaktorrisikokaries_plak_pH", sblmperawatanfaktorrisikokaries_plak_aktivitas, sblmperawatanfaktorrisikokaries_fluor_pastagigi, sblmperawatanfaktorrisikokaries_diet_gula, sblmperawatanfaktorrisikokaries_faktormodifikasi_obatpeningkata, sblmperawatanfaktorrisikokaries_faktormodifikasi_penyakitpenyeb, sblmperawatanfaktorrisikokaries_faktormodifikasi_protesa, sblmperawatanfaktorrisikokaries_faktormodifikasi_kariesaktif, sblmperawatanfaktorrisikokaries_faktormodifikasi_sikap, sblmperawatanfaktorrisikokaries_faktormodifikasi_keterangan, sblmperawatanfaktorrisikokaries_penilaianakhir_saliva, sblmperawatanfaktorrisikokaries_penilaianakhir_plak, sblmperawatanfaktorrisikokaries_penilaianakhir_diet, sblmperawatanfaktorrisikokaries_penilaianakhir_fluor, sblmperawatanfaktorrisikokaries_penilaianakhir_faktormodifikasi, ssdhperawatanfaktorrisikokaries_sikap, ssdhperawatanfaktorrisikokaries_status, ssdhperawatanfaktorrisikokaries_saliva_tanpastimulasi_hidrasi, ssdhperawatanfaktorrisikokaries_saliva_tanpastimulasi_viskosita, "ssdhperawatanfaktorrisikokaries_saliva_tanpastimulasi_pH", ssdhperawatanfaktorrisikokaries_saliva_denganstimulasi_hidrasi, ssdhperawatanfaktorrisikokaries_saliva_denganstimulasi_kecepata, ssdhperawatanfaktorrisikokaries_saliva_denganstimulasi_kapasita, "ssdhperawatanfaktorrisikokaries_saliva_denganstimulasi_pH", "ssdhperawatanfaktorrisikokaries_plak_pH", ssdhperawatanfaktorrisikokaries_plak_aktivitas, ssdhperawatanfaktorrisikokaries_fluor_pastagigi, ssdhperawatanfaktorrisikokaries_diet_gula, ssdhperawatanfaktorrisikokaries_faktormodifikasi_obatpeningkata, ssdhperawatanfaktorrisikokaries_faktormodifikasi_penyakitpenyeb, ssdhperawatanfaktorrisikokaries_faktormodifikasi_protesa, ssdhperawatanfaktorrisikokaries_faktormodifikasi_kariesaktif, ssdhperawatanfaktorrisikokaries_faktormodifikasi_sikap, ssdhperawatanfaktorrisikokaries_faktormodifikasi_keterangan, ssdhperawatanfaktorrisikokaries_penilaianakhir_saliva, ssdhperawatanfaktorrisikokaries_penilaianakhir_plak, ssdhperawatanfaktorrisikokaries_penilaianakhir_diet, ssdhperawatanfaktorrisikokaries_penilaianakhir_fluor, ssdhperawatanfaktorrisikokaries_penilaianakhir_faktormodifikasi, sikatgigi2xsehari, sikatgigi3xsehari, flossingsetiaphari, sikatinterdental, agenantibakteri_obatkumur, guladancemilandiantarawaktumakanutama, minumanasamtinggi, minumanberkafein, meningkatkanasupanair, obatkumurbakingsoda, konsumsimakananminumanberbahandasarsusu, permenkaretxylitolccpacp, pastagigi, kumursetiaphari, kumursetiapminggu, gelsetiaphari, gelsetiapminggu, perlu, tidakperlu, evaluasi_sikatgigi2xsehari, evaluasi_sikatgigi3xsehari, evaluasi_flossingsetiaphari, evaluasi_sikatinterdental, evaluasi_agenantibakteri_obatkumur, evaluasi_guladancemilandiantarawaktumakanutama, evaluasi_minumanasamtinggi, evaluasi_minumanberkafein, evaluasi_meningkatkanasupanair, evaluasi_obatkumurbakingsoda, evaluasi_konsumsimakananminumanberbahandasarsusu, evaluasi_permenkaretxylitolccpacp, evaluasi_pastagigi, evaluasi_kumursetiaphari, evaluasi_kumursetiapminggu, evaluasi_gelsetiaphari, evaluasi_gelsetiapminggu, evaluasi_perlu, evaluasi_tidakperlu, created_at, updated_at, uploadrestorasibefore, uploadrestorasiafter, sblmperawatanfaktorrisikokaries_fluor_airminum, sblmperawatanfaktorrisikokaries_fluor_topikal, sblmperawatanfaktorrisikokaries_diet_asam, ssdhperawatanfaktorrisikokaries_fluor_airminum, ssdhperawatanfaktorrisikokaries_fluor_topikal, ssdhperawatanfaktorrisikokaries_diet_asam, status_emr, status_penilaian) FROM stdin;
    public          rsyarsi    false    221   �M      �          0    16455    emrortodonsies 
   TABLE DATA           M  COPY public.emrortodonsies (id, noregister, noepisode, operator, nim, pembimbing, tanggal, namapasien, suku, umur, jeniskelamin, alamat, telepon, pekerjaan, rujukandari, namaayah, sukuayah, umurayah, namaibu, sukuibu, umuribu, pekerjaanorangtua, alamatorangtua, pendaftaran, pencetakan, pemasanganalat, waktuperawatan_retainer, keluhanutama, kelainanendoktrin, penyakitpadamasaanak, alergi, kelainansaluranpernapasan, tindakanoperasi, gigidesidui, gigibercampur, gigipermanen, durasi, frekuensi, intensitas, kebiasaanjelekketerangan, riwayatkeluarga, ayah, ibu, saudara, riwayatkeluargaketerangan, jasmani, mental, tinggibadan, beratbadan, indeksmassatubuh, statusgizi, kategori, lebarkepala, panjangkepala, indekskepala, bentukkepala, panjangmuka, lebarmuka, indeksmuka, bentukmuka, bentuk, profilmuka, senditemporomandibulat_tmj, tmj_keterangan, bibirposisiistirahat, tunusototmastikasi, tunusototmastikasi_keterangan, tunusototbibir, tunusototbibir_keterangan, freewayspace, pathofclosure, higienemulutohi, polaatrisi, regio, lingua, intraoral_lainlain, palatumvertikal, palatumlateral, gingiva, gingiva_keterangan, mukosa, mukosa_keterangan, frenlabiisuperior, frenlabiiinferior, frenlingualis, ketr, tonsila, fonetik, image_pemeriksaangigi, tampakdepantakterlihatgigi, fotomuka_bentukmuka, tampaksamping, fotomuka_profilmuka, tampakdepansenyumterlihatgigi, tampakmiring, tampaksampingkanan, tampakdepan, tampaksampingkiri, tampakoklusalatas, tampakoklusalbawah, bentuklengkunggigi_ra, bentuklengkunggigi_rb, malposisigigiindividual_rahangatas_kanan1, malposisigigiindividual_rahangatas_kanan2, malposisigigiindividual_rahangatas_kanan3, malposisigigiindividual_rahangatas_kanan4, malposisigigiindividual_rahangatas_kanan5, malposisigigiindividual_rahangatas_kanan6, malposisigigiindividual_rahangatas_kanan7, malposisigigiindividual_rahangatas_kiri1, malposisigigiindividual_rahangatas_kiri2, malposisigigiindividual_rahangatas_kiri3, malposisigigiindividual_rahangatas_kiri4, malposisigigiindividual_rahangatas_kiri5, malposisigigiindividual_rahangatas_kiri6, malposisigigiindividual_rahangatas_kiri7, malposisigigiindividual_rahangbawah_kanan1, malposisigigiindividual_rahangbawah_kanan2, malposisigigiindividual_rahangbawah_kanan3, malposisigigiindividual_rahangbawah_kanan4, malposisigigiindividual_rahangbawah_kanan5, malposisigigiindividual_rahangbawah_kanan6, malposisigigiindividual_rahangbawah_kanan7, malposisigigiindividual_rahangbawah_kiri1, malposisigigiindividual_rahangbawah_kiri2, malposisigigiindividual_rahangbawah_kiri3, malposisigigiindividual_rahangbawah_kiri4, malposisigigiindividual_rahangbawah_kiri5, malposisigigiindividual_rahangbawah_kiri6, malposisigigiindividual_rahangbawah_kiri7, overjet, overbite, palatalbite, deepbite, anterior_openbite, edgetobite, anterior_crossbite, posterior_openbite, scissorbite, cusptocuspbite, relasimolarpertamakanan, relasimolarpertamakiri, relasikaninuskanan, relasikaninuskiri, garistengahrahangbawahterhadaprahangatas, garisinterinsisivisentralterhadapgaristengahrahangra, garisinterinsisivisentralterhadapgaristengahrahangra_mm, garisinterinsisivisentralterhadapgaristengahrahangrb, garisinterinsisivisentralterhadapgaristengahrahangrb_mm, lebarmesiodistalgigi_rahangatas_kanan1, lebarmesiodistalgigi_rahangatas_kanan2, lebarmesiodistalgigi_rahangatas_kanan3, lebarmesiodistalgigi_rahangatas_kanan4, lebarmesiodistalgigi_rahangatas_kanan5, lebarmesiodistalgigi_rahangatas_kanan6, lebarmesiodistalgigi_rahangatas_kanan7, lebarmesiodistalgigi_rahangatas_kiri1, lebarmesiodistalgigi_rahangatas_kiri2, lebarmesiodistalgigi_rahangatas_kiri3, lebarmesiodistalgigi_rahangatas_kiri4, lebarmesiodistalgigi_rahangatas_kiri5, lebarmesiodistalgigi_rahangatas_kiri6, lebarmesiodistalgigi_rahangatas_kiri7, lebarmesiodistalgigi_rahangbawah_kanan1, lebarmesiodistalgigi_rahangbawah_kanan2, lebarmesiodistalgigi_rahangbawah_kanan3, lebarmesiodistalgigi_rahangbawah_kanan4, lebarmesiodistalgigi_rahangbawah_kanan5, lebarmesiodistalgigi_rahangbawah_kanan6, lebarmesiodistalgigi_rahangbawah_kanan7, lebarmesiodistalgigi_rahangbawah_kiri1, lebarmesiodistalgigi_rahangbawah_kiri2, lebarmesiodistalgigi_rahangbawah_kiri3, lebarmesiodistalgigi_rahangbawah_kiri4, lebarmesiodistalgigi_rahangbawah_kiri5, lebarmesiodistalgigi_rahangbawah_kiri6, lebarmesiodistalgigi_rahangbawah_kiri7, skemafotooklusalgigidarimodelstudi, jumlahmesiodistal, jarakp1p2pengukuran, jarakp1p2perhitungan, diskrepansip1p2_mm, diskrepansip1p2, jarakm1m1pengukuran, jarakm1m1perhitungan, diskrepansim1m2_mm, diskrepansim1m2, diskrepansi_keterangan, jumlahlebarmesiodistalgigidarim1m1, jarakp1p1tonjol, indeksp, lengkunggigiuntukmenampunggigigigi, jarakinterfossacaninus, indeksfc, lengkungbasaluntukmenampunggigigigi, inklinasigigigigiregioposterior, metodehowes_keterangan, aldmetode, overjetawal, overjetakhir, rahangatasdiskrepansi, rahangbawahdiskrepansi, fotosefalometri, fotopanoramik, maloklusiangleklas, hubunganskeletal, malrelasi, malposisi, estetik, dental, skeletal, fungsipenguyahanal, crowding, spacing, protrusif, retrusif, malposisiindividual, maloklusi_crossbite, maloklusi_lainlain, maloklusi_lainlainketerangan, rapencabutan, raekspansi, ragrinding, raplataktif, rbpencabutan, rbekspansi, rbgrinding, rbplataktif, analisisetiologimaloklusi, pasiendirujukkebagian, pencarianruanguntuk, koreksimalposisigigiindividual, retensi, pencarianruang, koreksimalposisigigiindividual_rahangatas, koreksimalposisigigiindividual_rahangbawah, intruksipadapasien, retainer, gambarplataktif_rahangatas, gambarplataktif_rahangbawah, keterangangambar, prognosis, prognosis_a, prognosis_b, prognosis_c, indikasiperawatan, created_at, updated_at, status_emr, status_penilaian) FROM stdin;
    public          rsyarsi    false    222   �v      �          0    16460    emrpedodontie_behaviorratings 
   TABLE DATA           �   COPY public.emrpedodontie_behaviorratings (id, emrid, frankscale, beforetreatment, duringtreatment, created_at, updated_at, userentryname) FROM stdin;
    public          rsyarsi    false    223   w      �          0    16465    emrpedodontie_treatmenplans 
   TABLE DATA           �   COPY public.emrpedodontie_treatmenplans (id, emrid, oralfinding, diagnosis, treatmentplanning, userentryname, updated_at, created_at, userentry, datetreatmentplanentry) FROM stdin;
    public          rsyarsi    false    224   %w      �          0    16470    emrpedodontie_treatmens 
   TABLE DATA           �   COPY public.emrpedodontie_treatmens (id, emrid, datetreatment, itemtreatment, userentryname, updated_at, created_at, supervisorname, supervisorvalidate, userentry, supervisousername) FROM stdin;
    public          rsyarsi    false    225   �x      �          0    16475    emrpedodonties 
   TABLE DATA           �  COPY public.emrpedodonties (id, tanggalmasuk, nim, namamahasiswa, tahunklinik, namasupervisor, tandatangan, namapasien, jeniskelamin, alamatpasien, usiapasien, pendidikan, tgllahirpasien, namaorangtua, telephone, pekerjaan, dokteranak, alamatpekerjaan, telephonedranak, anamnesis, noregister, noepisode, physicalgrowth, heartdesease, created_at, updated_at, bruiseeasily, anemia, hepatitis, allergic, takinganymedicine, takinganymedicineobat, beenhospitalized, beenhospitalizedalasan, toothache, childtoothache, firstdental, unfavorabledentalexperience, "where", reason, fingersucking, diffycultyopeningsjaw, howoftenbrushtooth, howoftenbrushtoothkali, usefluoridepasta, fluoridetreatmen, ifyes, bilateralsymmetry, asymmetry, straight, convex, concave, lipsseal, clicking, clickingleft, clickingright, pain, painleft, painright, bodypostur, gingivitis, stomatitis, dentalanomali, prematurloss, overretainedprimarytooth, odontogramfoto, gumboil, stageofdentition, franklscale_definitelynegative_before_treatment, franklscale_definitelynegative_during_treatment, franklscale_negative_before_treatment, franklscale_negative_during_treatment, franklscale_positive_before_treatment, franklscale_positive_during_treatment, franklscale_definitelypositive_before_treatment, franklscale_definitelypositive_during_treatment, buccal_18, buccal_17, buccal_16, buccal_15, buccal_14, buccal_13, buccal_12, buccal_11, buccal_21, buccal_22, buccal_23, buccal_24, buccal_25, buccal_26, buccal_27, buccal_28, palatal_55, palatal_54, palatal_53, palatal_52, palatal_51, palatal_61, palatal_62, palatal_63, palatal_64, palatal_65, buccal_85, buccal_84, buccal_83, buccal_82, buccal_81, buccal_71, buccal_72, buccal_73, buccal_74, buccal_75, palatal_48, palatal_47, palatal_46, palatal_45, palatal_44, palatal_43, palatal_42, palatal_41, palatal_31, palatal_32, palatal_33, palatal_34, palatal_35, palatal_36, palatal_37, palatal_38, dpalatal, epalatal, fpalatal, defpalatal, dlingual, elingual, flingual, deflingual, status_emr, status_penilaian) FROM stdin;
    public          rsyarsi    false    226   oy      �          0    16480    emrperiodontie_soaps 
   TABLE DATA           �   COPY public.emrperiodontie_soaps (id, datesoap, terapi_s, terapi_o, terapi_a, terapi_p, user_entry, user_entry_name, user_verify, user_verify_name, created_at, updated_at, idemr, active, date_verify) FROM stdin;
    public          rsyarsi    false    227   �y      �          0    16486    emrperiodonties 
   TABLE DATA           �5  COPY public.emrperiodonties (id, nama_mahasiswa, npm, tahun_klinik, opsi_imagemahasiswa, noregister, noepisode, no_rekammedik, kasus_pasien, tanggal_pemeriksaan, pendidikan_pasien, nama_pasien, umur_pasien, jenis_kelamin_pasien, alamat, no_telephone_pasien, pemeriksa, operator1, operator2, operator3, operator4, konsuldari, keluhanutama, anamnesis, gusi_mudah_berdarah, gusi_mudah_berdarah_lainlain, penyakit_sistemik, penyakit_sistemik_bilaada, penyakit_sistemik_obat, diabetes_melitus, diabetes_melituskadargula, merokok, merokok_perhari, merokok_tahun_awal, merokok_tahun_akhir, gigi_pernah_tanggal_dalam_keadaan_baik, keadaan_umum, tekanan_darah, extra_oral, intra_oral, oral_hygiene_bop, oral_hygiene_ci, oral_hygiene_pi, oral_hygiene_ohis, kesimpulan_ohis, rakn_keaadan_gingiva, rakn_karang_gigi, rakn_oklusi, rakn_artikulasi, rakn_abrasi_atrisi_abfraksi, ram_keaadan_gingiva, ram_karang_gigi, ram_oklusi, ram_artikulasi, ram_abrasi_atrisi_abfraksi, rakr_keaadan_gingiva, rakr_karang_gigi, rakr_oklusi, rakr_artikulasi, rakr_abrasi_atrisi_abfraksi, rbkn_keaadan_gingiva, rbkn_karang_gigi, rbkn_oklusi, rbkn_artikulasi, rbkn_abrasi_atrisi_abfraksi, rbm_keaadan_gingiva, rbm_karang_gigi, rbm_oklusi, rbm_artikulasi, rbm_abrasi_atrisi_abfraksi, rbkr_keaadan_gingiva, rbkr_karang_gigi, rbkr_oklusi, rbkr_artikulasi, rbkr_abrasi_atrisi_abfraksi, rakn_1_v, rakn_1_g, rakn_1_pm, rakn_1_pb, rakn_1_pd, rakn_1_pp, rakn_1_o, rakn_1_r, rakn_1_la, rakn_1_mp, rakn_1_bop, rakn_1_tk, rakn_1_fi, rakn_1_k, rakn_1_t, rakn_2_v, rakn_2_g, rakn_2_pm, rakn_2_pb, rakn_2_pd, rakn_2_pp, rakn_2_o, rakn_2_r, rakn_2_la, rakn_2_mp, rakn_2_bop, rakn_2_tk, rakn_2_fi, rakn_2_k, rakn_2_t, rakn_3_v, rakn_3_g, rakn_3_pm, rakn_3_pb, rakn_3_pd, rakn_3_pp, rakn_3_o, rakn_3_r, rakn_3_la, rakn_3_mp, rakn_3_bop, rakn_3_tk, rakn_3_fi, rakn_3_k, rakn_3_t, rakn_4_v, rakn_4_g, rakn_4_pm, rakn_4_pb, rakn_4_pd, rakn_4_pp, rakn_4_o, rakn_4_r, rakn_4_la, rakn_4_mp, rakn_4_bop, rakn_4_tk, rakn_4_fi, rakn_4_k, rakn_4_t, rakn_5_v, rakn_5_g, rakn_5_pm, rakn_5_pb, rakn_5_pd, rakn_5_pp, rakn_5_o, rakn_5_r, rakn_5_la, rakn_5_mp, rakn_5_bop, rakn_5_tk, rakn_5_fi, rakn_5_k, rakn_5_t, rakn_6_v, rakn_6_g, rakn_6_pm, rakn_6_pb, rakn_6_pd, rakn_6_pp, rakn_6_o, rakn_6_r, rakn_6_la, rakn_6_mp, rakn_6_bop, rakn_6_tk, rakn_6_fi, rakn_6_k, rakn_6_t, rakn_7_v, rakn_7_g, rakn_7_pm, rakn_7_pb, rakn_7_pd, rakn_7_pp, rakn_7_o, rakn_7_r, rakn_7_la, rakn_7_mp, rakn_7_bop, rakn_7_tk, rakn_7_fi, rakn_7_k, rakn_7_t, rakn_8_v, rakn_8_g, rakn_8_pm, rakn_8_pb, rakn_8_pd, rakn_8_pp, rakn_8_o, rakn_8_r, rakn_8_la, rakn_8_mp, rakn_8_bop, rakn_8_tk, rakn_8_fi, rakn_8_k, rakn_8_t, rakr_1_v, rakr_1_g, rakr_1_pm, rakr_1_pb, rakr_1_pd, rakr_1_pp, rakr_1_o, rakr_1_r, rakr_1_la, rakr_1_mp, rakr_1_bop, rakr_1_tk, rakr_1_fi, rakr_1_k, rakr_1_t, rakr_2_v, rakr_2_g, rakr_2_pm, rakr_2_pb, rakr_2_pd, rakr_2_pp, rakr_2_o, rakr_2_r, rakr_2_la, rakr_2_mp, rakr_2_bop, rakr_2_tk, rakr_2_fi, rakr_2_k, rakr_2_t, rakr_3_v, rakr_3_g, rakr_3_pm, rakr_3_pb, rakr_3_pd, rakr_3_pp, rakr_3_o, rakr_3_r, rakr_3_la, rakr_3_mp, rakr_3_bop, rakr_3_tk, rakr_3_fi, rakr_3_k, rakr_3_t, rakr_4_v, rakr_4_g, rakr_4_pm, rakr_4_pb, rakr_4_pd, rakr_4_pp, rakr_4_o, rakr_4_r, rakr_4_la, rakr_4_mp, rakr_4_bop, rakr_4_tk, rakr_4_fi, rakr_4_k, rakr_4_t, rakr_5_v, rakr_5_g, rakr_5_pm, rakr_5_pb, rakr_5_pd, rakr_5_pp, rakr_5_o, rakr_5_r, rakr_5_la, rakr_5_mp, rakr_5_bop, rakr_5_tk, rakr_5_fi, rakr_5_k, rakr_5_t, rakr_6_v, rakr_6_g, rakr_6_pm, rakr_6_pb, rakr_6_pd, rakr_6_pp, rakr_6_o, rakr_6_r, rakr_6_la, rakr_6_mp, rakr_6_bop, rakr_6_tk, rakr_6_fi, rakr_6_k, rakr_6_t, rakr_7_v, rakr_7_g, rakr_7_pm, rakr_7_pb, rakr_7_pd, rakr_7_pp, rakr_7_o, rakr_7_r, rakr_7_la, rakr_7_mp, rakr_7_bop, rakr_7_tk, rakr_7_fi, rakr_7_k, rakr_7_t, rakr_8_v, rakr_8_g, rakr_8_pm, rakr_8_pb, rakr_8_pd, rakr_8_pp, rakr_8_o, rakr_8_r, rakr_8_la, rakr_8_mp, rakr_8_bop, rakr_8_tk, rakr_8_fi, rakr_8_k, rakr_8_t, rbkn_1_v, rbkn_1_g, rbkn_1_pm, rbkn_1_pb, rbkn_1_pd, rbkn_1_pp, rbkn_1_o, rbkn_1_r, rbkn_1_la, rbkn_1_mp, rbkn_1_bop, rbkn_1_tk, rbkn_1_fi, rbkn_1_k, rbkn_1_t, rbkn_2_v, rbkn_2_g, rbkn_2_pm, rbkn_2_pb, rbkn_2_pd, rbkn_2_pp, rbkn_2_o, rbkn_2_r, rbkn_2_la, rbkn_2_mp, rbkn_2_bop, rbkn_2_tk, rbkn_2_fi, rbkn_2_k, rbkn_2_t, rbkn_3_v, rbkn_3_g, rbkn_3_pm, rbkn_3_pb, rbkn_3_pd, rbkn_3_pp, rbkn_3_o, rbkn_3_r, rbkn_3_la, rbkn_3_mp, rbkn_3_bop, rbkn_3_tk, rbkn_3_fi, rbkn_3_k, rbkn_3_t, rbkn_4_v, rbkn_4_g, rbkn_4_pm, rbkn_4_pb, rbkn_4_pd, rbkn_4_pp, rbkn_4_o, rbkn_4_r, rbkn_4_la, rbkn_4_mp, rbkn_4_bop, rbkn_4_tk, rbkn_4_fi, rbkn_4_k, rbkn_4_t, rbkn_5_v, rbkn_5_g, rbkn_5_pm, rbkn_5_pb, rbkn_5_pd, rbkn_5_pp, rbkn_5_o, rbkn_5_r, rbkn_5_la, rbkn_5_mp, rbkn_5_bop, rbkn_5_tk, rbkn_5_fi, rbkn_5_k, rbkn_5_t, rbkn_6_v, rbkn_6_g, rbkn_6_pm, rbkn_6_pb, rbkn_6_pd, rbkn_6_pp, rbkn_6_o, rbkn_6_r, rbkn_6_la, rbkn_6_mp, rbkn_6_bop, rbkn_6_tk, rbkn_6_fi, rbkn_6_k, rbkn_6_t, rbkn_7_v, rbkn_7_g, rbkn_7_pm, rbkn_7_pb, rbkn_7_pd, rbkn_7_pp, rbkn_7_o, rbkn_7_r, rbkn_7_la, rbkn_7_mp, rbkn_7_bop, rbkn_7_tk, rbkn_7_fi, rbkn_7_k, rbkn_7_t, rbkn_8_v, rbkn_8_g, rbkn_8_pm, rbkn_8_pb, rbkn_8_pd, rbkn_8_pp, rbkn_8_o, rbkn_8_r, rbkn_8_la, rbkn_8_mp, rbkn_8_bop, rbkn_8_tk, rbkn_8_fi, rbkn_8_k, rbkn_8_t, rbkr_1_v, rbkr_1_g, rbkr_1_pm, rbkr_1_pb, rbkr_1_pd, rbkr_1_pp, rbkr_1_o, rbkr_1_r, rbkr_1_la, rbkr_1_mp, rbkr_1_bop, rbkr_1_tk, rbkr_1_fi, rbkr_1_k, rbkr_1_t, rbkr_2_v, rbkr_2_g, rbkr_2_pm, rbkr_2_pb, rbkr_2_pd, rbkr_2_pp, rbkr_2_o, rbkr_2_r, rbkr_2_la, rbkr_2_mp, rbkr_2_bop, rbkr_2_tk, rbkr_2_fi, rbkr_2_k, rbkr_2_t, rbkr_3_v, rbkr_3_g, rbkr_3_pm, rbkr_3_pb, rbkr_3_pd, rbkr_3_pp, rbkr_3_o, rbkr_3_r, rbkr_3_la, rbkr_3_mp, rbkr_3_bop, rbkr_3_tk, rbkr_3_fi, rbkr_3_k, rbkr_3_t, rbkr_4_v, rbkr_4_g, rbkr_4_pm, rbkr_4_pb, rbkr_4_pd, rbkr_4_pp, rbkr_4_o, rbkr_4_r, rbkr_4_la, rbkr_4_mp, rbkr_4_bop, rbkr_4_tk, rbkr_4_fi, rbkr_4_k, rbkr_4_t, rbkr_5_v, rbkr_5_g, rbkr_5_pm, rbkr_5_pb, rbkr_5_pd, rbkr_5_pp, rbkr_5_o, rbkr_5_r, rbkr_5_la, rbkr_5_mp, rbkr_5_bop, rbkr_5_tk, rbkr_5_fi, rbkr_5_k, rbkr_5_t, rbkr_6_v, rbkr_6_g, rbkr_6_pm, rbkr_6_pb, rbkr_6_pd, rbkr_6_pp, rbkr_6_o, rbkr_6_r, rbkr_6_la, rbkr_6_mp, rbkr_6_bop, rbkr_6_tk, rbkr_6_fi, rbkr_6_k, rbkr_6_t, rbkr_7_v, rbkr_7_g, rbkr_7_pm, rbkr_7_pb, rbkr_7_pd, rbkr_7_pp, rbkr_7_o, rbkr_7_r, rbkr_7_la, rbkr_7_mp, rbkr_7_bop, rbkr_7_tk, rbkr_7_fi, rbkr_7_k, rbkr_7_t, rbkr_8_v, rbkr_8_g, rbkr_8_pm, rbkr_8_pb, rbkr_8_pd, rbkr_8_pp, rbkr_8_o, rbkr_8_r, rbkr_8_la, rbkr_8_mp, rbkr_8_bop, rbkr_8_tk, rbkr_8_fi, rbkr_8_k, rbkr_8_t, diagnosis_klinik, gambaran_radiografis, indikasi, terapi, keterangan, prognosis_umum, prognosis_lokal, p1_tanggal, p1_indeksplak_ra_el16_b, p1_indeksplak_ra_el12_b, p1_indeksplak_ra_el11_b, p1_indeksplak_ra_el21_b, p1_indeksplak_ra_el22_b, p1_indeksplak_ra_el24_b, p1_indeksplak_ra_el26_b, p1_indeksplak_ra_el16_l, p1_indeksplak_ra_el12_l, p1_indeksplak_ra_el11_l, p1_indeksplak_ra_el21_l, p1_indeksplak_ra_el22_l, p1_indeksplak_ra_el24_l, p1_indeksplak_ra_el26_l, p1_indeksplak_rb_el36_b, p1_indeksplak_rb_el34_b, p1_indeksplak_rb_el32_b, p1_indeksplak_rb_el31_b, p1_indeksplak_rb_el41_b, p1_indeksplak_rb_el42_b, p1_indeksplak_rb_el46_b, p1_indeksplak_rb_el36_l, p1_indeksplak_rb_el34_l, p1_indeksplak_rb_el32_l, p1_indeksplak_rb_el31_l, p1_indeksplak_rb_el41_l, p1_indeksplak_rb_el42_l, p1_indeksplak_rb_el46_l, p1_bop_ra_el16_b, p1_bop_ra_el12_b, p1_bop_ra_el11_b, p1_bop_ra_el21_b, p1_bop_ra_el22_b, p1_bop_ra_el24_b, p1_bop_ra_el26_b, p1_bop_ra_el16_l, p1_bop_ra_el12_l, p1_bop_ra_el11_l, p1_bop_ra_el21_l, p1_bop_ra_el22_l, p1_bop_ra_el24_l, p1_bop_ra_el26_l, p1_bop_rb_el36_b, p1_bop_rb_el34_b, p1_bop_rb_el32_b, p1_bop_rb_el31_b, p1_bop_rb_el41_b, p1_bop_rb_el42_b, p1_bop_rb_el46_b, p1_bop_rb_el36_l, p1_bop_rb_el34_l, p1_bop_rb_el32_l, p1_bop_rb_el31_l, p1_bop_rb_el41_l, p1_bop_rb_el42_l, p1_bop_rb_el46_l, p1_indekskalkulus_ra_el16_b, p1_indekskalkulus_ra_el26_b, p1_indekskalkulus_ra_el16_l, p1_indekskalkulus_ra_el26_l, p1_indekskalkulus_rb_el36_b, p1_indekskalkulus_rb_el34_b, p1_indekskalkulus_rb_el32_b, p1_indekskalkulus_rb_el31_b, p1_indekskalkulus_rb_el41_b, p1_indekskalkulus_rb_el42_b, p1_indekskalkulus_rb_el46_b, p1_indekskalkulus_rb_el36_l, p1_indekskalkulus_rb_el34_l, p1_indekskalkulus_rb_el32_l, p1_indekskalkulus_rb_el31_l, p1_indekskalkulus_rb_el41_l, p1_indekskalkulus_rb_el42_l, p1_indekskalkulus_rb_el46_l, p2_tanggal, p2_indeksplak_ra_el16_b, p2_indeksplak_ra_el12_b, p2_indeksplak_ra_el11_b, p2_indeksplak_ra_el21_b, p2_indeksplak_ra_el22_b, p2_indeksplak_ra_el24_b, p2_indeksplak_ra_el26_b, p2_indeksplak_ra_el16_l, p2_indeksplak_ra_el12_l, p2_indeksplak_ra_el11_l, p2_indeksplak_ra_el21_l, p2_indeksplak_ra_el22_l, p2_indeksplak_ra_el24_l, p2_indeksplak_ra_el26_l, p2_indeksplak_rb_el36_b, p2_indeksplak_rb_el34_b, p2_indeksplak_rb_el32_b, p2_indeksplak_rb_el31_b, p2_indeksplak_rb_el41_b, p2_indeksplak_rb_el42_b, p2_indeksplak_rb_el46_b, p2_indeksplak_rb_el36_l, p2_indeksplak_rb_el34_l, p2_indeksplak_rb_el32_l, p2_indeksplak_rb_el31_l, p2_indeksplak_rb_el41_l, p2_indeksplak_rb_el42_l, p2_indeksplak_rb_el46_l, p2_bop_ra_el16_b, p2_bop_ra_el12_b, p2_bop_ra_el11_b, p2_bop_ra_el21_b, p2_bop_ra_el22_b, p2_bop_ra_el24_b, p2_bop_ra_el26_b, p2_bop_ra_el16_l, p2_bop_ra_el12_l, p2_bop_ra_el11_l, p2_bop_ra_el21_l, p2_bop_ra_el22_l, p2_bop_ra_el24_l, p2_bop_ra_el26_l, p2_bop_rb_el36_b, p2_bop_rb_el34_b, p2_bop_rb_el32_b, p2_bop_rb_el31_b, p2_bop_rb_el41_b, p2_bop_rb_el42_b, p2_bop_rb_el46_b, p2_bop_rb_el36_l, p2_bop_rb_el34_l, p2_bop_rb_el32_l, p2_bop_rb_el31_l, p2_bop_rb_el41_l, p2_bop_rb_el42_l, p2_bop_rb_el46_l, p2_indekskalkulus_ra_el16_b, p2_indekskalkulus_ra_el26_b, p2_indekskalkulus_ra_el16_l, p2_indekskalkulus_ra_el26_l, p2_indekskalkulus_rb_el36_b, p2_indekskalkulus_rb_el34_b, p2_indekskalkulus_rb_el32_b, p2_indekskalkulus_rb_el31_b, p2_indekskalkulus_rb_el41_b, p2_indekskalkulus_rb_el42_b, p2_indekskalkulus_rb_el46_b, p2_indekskalkulus_rb_el36_l, p2_indekskalkulus_rb_el34_l, p2_indekskalkulus_rb_el32_l, p2_indekskalkulus_rb_el31_l, p2_indekskalkulus_rb_el41_l, p2_indekskalkulus_rb_el42_l, p2_indekskalkulus_rb_el46_l, p3_tanggal, p3_indeksplak_ra_el16_b, p3_indeksplak_ra_el12_b, p3_indeksplak_ra_el11_b, p3_indeksplak_ra_el21_b, p3_indeksplak_ra_el22_b, p3_indeksplak_ra_el24_b, p3_indeksplak_ra_el26_b, p3_indeksplak_ra_el16_l, p3_indeksplak_ra_el12_l, p3_indeksplak_ra_el11_l, p3_indeksplak_ra_el21_l, p3_indeksplak_ra_el22_l, p3_indeksplak_ra_el24_l, p3_indeksplak_ra_el26_l, p3_indeksplak_rb_el36_b, p3_indeksplak_rb_el34_b, p3_indeksplak_rb_el32_b, p3_indeksplak_rb_el31_b, p3_indeksplak_rb_el41_b, p3_indeksplak_rb_el42_b, p3_indeksplak_rb_el46_b, p3_indeksplak_rb_el36_l, p3_indeksplak_rb_el34_l, p3_indeksplak_rb_el32_l, p3_indeksplak_rb_el31_l, p3_indeksplak_rb_el41_l, p3_indeksplak_rb_el42_l, p3_indeksplak_rb_el46_l, p3_bop_ra_el16_b, p3_bop_ra_el12_b, p3_bop_ra_el11_b, p3_bop_ra_el21_b, p3_bop_ra_el22_b, p3_bop_ra_el24_b, p3_bop_ra_el26_b, p3_bop_ra_el16_l, p3_bop_ra_el12_l, p3_bop_ra_el11_l, p3_bop_ra_el21_l, p3_bop_ra_el22_l, p3_bop_ra_el24_l, p3_bop_ra_el26_l, p3_bop_rb_el36_b, p3_bop_rb_el34_b, p3_bop_rb_el32_b, p3_bop_rb_el31_b, p3_bop_rb_el41_b, p3_bop_rb_el42_b, p3_bop_rb_el46_b, p3_bop_rb_el36_l, p3_bop_rb_el34_l, p3_bop_rb_el32_l, p3_bop_rb_el31_l, p3_bop_rb_el41_l, p3_bop_rb_el42_l, p3_bop_rb_el46_l, p3_indekskalkulus_ra_el16_b, p3_indekskalkulus_ra_el26_b, p3_indekskalkulus_ra_el16_l, p3_indekskalkulus_ra_el26_l, p3_indekskalkulus_rb_el36_b, p3_indekskalkulus_rb_el34_b, p3_indekskalkulus_rb_el32_b, p3_indekskalkulus_rb_el31_b, p3_indekskalkulus_rb_el41_b, p3_indekskalkulus_rb_el42_b, p3_indekskalkulus_rb_el46_b, p3_indekskalkulus_rb_el36_l, p3_indekskalkulus_rb_el34_l, p3_indekskalkulus_rb_el32_l, p3_indekskalkulus_rb_el31_l, p3_indekskalkulus_rb_el41_l, p3_indekskalkulus_rb_el42_l, p3_indekskalkulus_rb_el46_l, foto_klinis_oklusi_arah_kiri, foto_klinis_oklusi_arah_kanan, foto_klinis_oklusi_arah_anterior, foto_klinis_oklusal_rahang_atas, foto_klinis_oklusal_rahang_bawah, foto_klinis_before, foto_klinis_after, foto_ronsen_panoramik, terapi_s, terapi_o, terapi_a, terapi_p, terapi_ohis, terapi_bop, terapi_pm18, terapi_pm17, terapi_pm16, terapi_pm15, terapi_pm14, terapi_pm13, terapi_pm12, terapi_pm11, terapi_pm21, terapi_pm22, terapi_pm23, terapi_pm24, terapi_pm25, terapi_pm26, terapi_pm27, terapi_pm28, terapi_pm38, terapi_pm37, terapi_pm36, terapi_pm35, terapi_pm34, terapi_pm33, terapi_pm32, terapi_pm31, terapi_pm41, terapi_pm42, terapi_pm43, terapi_pm44, terapi_pm45, terapi_pm46, terapi_pm47, terapi_pm48, terapi_pb18, terapi_pb17, terapi_pb16, terapi_pb15, terapi_pb14, terapi_pb13, terapi_pb12, terapi_pb11, terapi_pb21, terapi_pb22, terapi_pb23, terapi_pb24, terapi_pb25, terapi_pb26, terapi_pb27, terapi_pb28, terapi_pb38, terapi_pb37, terapi_pb36, terapi_pb35, terapi_pb34, terapi_pb33, terapi_pb32, terapi_pb31, terapi_pb41, terapi_pb42, terapi_pb43, terapi_pb44, terapi_pb45, terapi_pb46, terapi_pb47, terapi_pb48, terapi_pd18, terapi_pd17, terapi_pd16, terapi_pd15, terapi_pd14, terapi_pd13, terapi_pd12, terapi_pd11, terapi_pd21, terapi_pd22, terapi_pd23, terapi_pd24, terapi_pd25, terapi_pd26, terapi_pd27, terapi_pd28, terapi_pd38, terapi_pd37, terapi_pd36, terapi_pd35, terapi_pd34, terapi_pd33, terapi_pd32, terapi_pd31, terapi_pd41, terapi_pd42, terapi_pd43, terapi_pd44, terapi_pd45, terapi_pd46, terapi_pd47, terapi_pd48, terapi_pl18, terapi_pl17, terapi_pl16, terapi_pl15, terapi_pl14, terapi_pl13, terapi_pl12, terapi_pl11, terapi_pl21, terapi_pl22, terapi_pl23, terapi_pl24, terapi_pl25, terapi_pl26, terapi_pl27, terapi_pl28, terapi_pl38, terapi_pl37, terapi_pl36, terapi_pl35, terapi_pl34, terapi_pl33, terapi_pl32, terapi_pl31, terapi_pl41, terapi_pl42, terapi_pl43, terapi_pl44, terapi_pl45, terapi_pl46, terapi_pl47, terapi_pl48, created_at, updated_at, status_emr, status_penilaian) FROM stdin;
    public          rsyarsi    false    228   �z      �          0    16491    emrprostodontie_logbooks 
   TABLE DATA           �   COPY public.emrprostodontie_logbooks (id, dateentri, work, usernameentry, usernameentryname, lectureid, lecturename, updated_at, created_at, emrid, dateverifylecture) FROM stdin;
    public          rsyarsi    false    229   ك      �          0    16496    emrprostodonties 
   TABLE DATA           �  COPY public.emrprostodonties (id, noregister, noepisode, nomorrekammedik, tanggal, namapasien, pekerjaan, jeniskelamin, alamatpasien, namaoperator, nomortelpon, npm, keluhanutama, riwayatgeligi, pengalamandengangigitiruan, estetis, fungsibicara, penguyahan, pembiayaan, lainlain, wajah, profilmuka, pupil, tragus, hidung, pernafasanmelaluihidung, bibiratas, bibiratas_b, bibirbawah, bibirbawah_b, submandibulariskanan, submandibulariskanan_b, submandibulariskiri, submandibulariskiri_b, sublingualis, sublingualis_b, sisikiri, sisikirisejak, sisikanan, sisikanansejak, membukamulut, membukamulut_b, kelainanlain, higienemulut, salivakuantitas, salivakonsisten, lidahukuran, lidahposisiwright, lidahmobilitas, refleksmuntah, mukosamulut, mukosamulutberupa, gigitan, gigitanbilaada, gigitanterbuka, gigitanterbukaregion, gigitansilang, gigitansilangregion, hubunganrahang, pemeriksaanrontgendental, elemengigi, pemeriksaanrontgenpanoramik, pemeriksaanrontgentmj, frakturgigi, frakturarah, frakturbesar, intraorallainlain, perbandinganmahkotadanakargigi, interprestasifotorontgen, intraoralkebiasaanburuk, intraoralkebiasaanburukberupa, pemeriksaanodontogram_11_51, pemeriksaanodontogram_12_52, pemeriksaanodontogram_13_53, pemeriksaanodontogram_14_54, pemeriksaanodontogram_15_55, pemeriksaanodontogram_16, pemeriksaanodontogram_17, pemeriksaanodontogram_18, pemeriksaanodontogram_61_21, pemeriksaanodontogram_62_22, pemeriksaanodontogram_63_23, pemeriksaanodontogram_64_24, pemeriksaanodontogram_65_25, pemeriksaanodontogram_26, pemeriksaanodontogram_27, pemeriksaanodontogram_28, pemeriksaanodontogram_48, pemeriksaanodontogram_47, pemeriksaanodontogram_46, pemeriksaanodontogram_45_85, pemeriksaanodontogram_44_84, pemeriksaanodontogram_43_83, pemeriksaanodontogram_42_82, pemeriksaanodontogram_41_81, pemeriksaanodontogram_38, pemeriksaanodontogram_37, pemeriksaanodontogram_36, pemeriksaanodontogram_75_35, pemeriksaanodontogram_74_34, pemeriksaanodontogram_73_33, pemeriksaanodontogram_72_32, pemeriksaanodontogram_71_31, rahangataspostkiri, rahangataspostkanan, rahangatasanterior, rahangbawahpostkiri, rahangbawahpostkanan, rahangbawahanterior, rahangatasbentukpostkiri, rahangatasbentukpostkanan, rahangatasbentukanterior, rahangatasketinggianpostkiri, rahangatasketinggianpostkanan, rahangatasketinggiananterior, rahangatastahananjaringanpostkiri, rahangatastahananjaringanpostkanan, rahangatastahananjaringananterior, rahangatasbentukpermukaanpostkiri, rahangatasbentukpermukaanpostkanan, rahangatasbentukpermukaananterior, rahangbawahbentukpostkiri, rahangbawahbentukpostkanan, rahangbawahbentukanterior, rahangbawahketinggianpostkiri, rahangbawahketinggianpostkanan, rahangbawahketinggiananterior, rahangbawahtahananjaringanpostkiri, rahangbawahtahananjaringanpostkanan, rahangbawahtahananjaringananterior, rahangbawahbentukpermukaanpostkiri, rahangbawahbentukpermukaanpostkanan, rahangbawahbentukpermukaananterior, anterior, prosteriorkiri, prosteriorkanan, labialissuperior, labialisinferior, bukalisrahangataskiri, bukalisrahangataskanan, bukalisrahangbawahkiri, bukalisrahangbawahkanan, lingualis, palatum, kedalaman, toruspalatinus, palatummolle, tuberorositasalveolariskiri, tuberorositasalveolariskanan, ruangretromilahioidkiri, ruangretromilahioidkanan, bentuklengkungrahangatas, bentuklengkungrahangbawah, perlekatandasarmulut, pemeriksaanlain_lainlain, sikapmental, diagnosa, rahangatas, rahangataselemen, rahangbawah, rahangbawahelemen, gigitiruancekat, gigitiruancekatelemen, perawatanperiodontal, perawatanbedah, perawatanbedah_ada, perawatanbedahelemen, perawatanbedahlainlain, konservasigigi, konservasigigielemen, rekonturing, adapembuatanmahkota, pengasahangigimiring, pengasahangigiextruded, rekonturinglainlain, macamcetakan_ra, acamcetakan_rb, warnagigi, klasifikasidaerahtidakbergigirahangatas, klasifikasidaerahtidakbergigirahangbawah, gigipenyangga, direk, indirek, platdasar, anasirgigi, prognosis, prognosisalasan, reliningregio, reliningregiotanggal, reparasiregio, reparasiregiotanggal, perawatanulangsebab, perawatanulanglainlain, perawatanulanglainlaintanggal, perawatanulangketerangan, created_at, updated_at, nim, designngigi, designngigitext, fotoodontogram, status_emr, status_penilaian) FROM stdin;
    public          rsyarsi    false    230   ��      �          0    16501    emrradiologies 
   TABLE DATA           �  COPY public.emrradiologies (id, noepisode, noregistrasi, nomr, namapasien, alamat, usia, tglpotret, diagnosaklinik, foto, jenisradiologi, periaprikal_int_mahkota, periaprikal_int_akar, periaprikal_int_membran, periaprikal_int_lamina_dura, periaprikal_int_furkasi, periaprikal_int_alveoral, periaprikal_int_kondisi_periaprikal, periaprikal_int_kesan, periaprikal_int_lesigigi, periaprikal_int_suspek, nim, namaoperator, namadokter, panoramik_miising_teeth, panoramik_missing_agnesia, panoramik_persistensi, panoramik_impaki, panoramik_kondisi_mahkota, panoramik_kondisi_akar, panoramik_kondisi_alveoral, panoramik_kondisi_periaprikal, panoramik_area_dua, oklusal_kesan, oklusal_suspek_radiognosis, status_emr, status_penilaian, jenis_radiologi, url) FROM stdin;
    public          rsyarsi    false    231   Y�      �          0    16506    failed_jobs 
   TABLE DATA           a   COPY public.failed_jobs (id, uuid, connection, queue, payload, exception, failed_at) FROM stdin;
    public          rsyarsi    false    232   ��      �          0    16513    finalassesment_konservasis 
   TABLE DATA             COPY public.finalassesment_konservasis (uuid, nim, name, kelompok, tumpatan_komposisi_1, tumpatan_komposisi_2, tumpatan_komposisi_3, tumpatan_komposisi_4, tumpatan_komposisi_5, totalakhir, grade, keterangan_grade, yearid, semesterid, studentid) FROM stdin;
    public          rsyarsi    false    234   ��      �          0    16519    finalassesment_orthodonties 
   TABLE DATA           �  COPY public.finalassesment_orthodonties (id, nim, name, kelompok, anamnesis, foto_oi, cetak_rahang, modelstudi_one, analisissefalometri, fotografi_oral, rencana_perawatan, insersi_alat, aktivasi_alat, kontrol, model_studi_2, penilaian_hasil_perawatan, laporan_khusus, totalakhir, grade, keterangan_grade, nilaipekerjaanklinik, nilailaporankasus, analisismodel, yearid, semesterid, studentid) FROM stdin;
    public          rsyarsi    false    235   �      �          0    16525    finalassesment_periodonties 
   TABLE DATA           �   COPY public.finalassesment_periodonties (id, nim, name, kelompok, anamnesis_scalingmanual, anamnesis_uss, uss_desensitisasi, splinting_fiber, diskusi_tatapmuka, dops, totalakhir, grade, keterangan_grade, yearid, semesterid, studentid) FROM stdin;
    public          rsyarsi    false    236   ��      �          0    16531    finalassesment_prostodonties 
   TABLE DATA           �   COPY public.finalassesment_prostodonties (id, nim, name, kelompok, penyajian_diskusi, gigi_tiruan_lepas, dops_fungsional, totalakhir, grade, keterangan_grade, yearid, semesterid, studentid) FROM stdin;
    public          rsyarsi    false    237   ��      �          0    16537    finalassesment_radiologies 
   TABLE DATA           b  COPY public.finalassesment_radiologies (uuid, nim, name, kelompok, videoteknikradiografi_periapikalbisektris, videoteknikradiografi_oklusal, interpretasi_foto_periapikal, interpretasi_foto_panoramik, interpretasi_foto_oklusal, rujukan_medik, penyaji_jr, dops, ujian_bagian, totalakhir, grade, keterangan_grade, yearid, semesterid, studentid) FROM stdin;
    public          rsyarsi    false    238   ��      �          0    16543 	   hospitals 
   TABLE DATA           M   COPY public.hospitals (id, name, active, created_at, updated_at) FROM stdin;
    public          rsyarsi    false    239   ��      �          0    16547    lectures 
   TABLE DATA           n   COPY public.lectures (id, specialistid, name, doctotidsimrs, active, created_at, updated_at, nim) FROM stdin;
    public          rsyarsi    false    240   7�      �          0    16550 
   migrations 
   TABLE DATA           :   COPY public.migrations (id, migration, batch) FROM stdin;
    public          rsyarsi    false    241   [�      �          0    16554    password_resets 
   TABLE DATA           C   COPY public.password_resets (email, token, created_at) FROM stdin;
    public          rsyarsi    false    243   ��      �          0    16559    patients 
   TABLE DATA           �   COPY public.patients (noepisode, noregistrasi, nomr, patientname, namajaminan, noantrianall, gander, date_of_birth, address, idunit, visit_date, namaunit, iddokter, namadokter, patienttype, statusid, created_at) FROM stdin;
    public          rsyarsi    false    244   ��      �          0    16564    personal_access_tokens 
   TABLE DATA           �   COPY public.personal_access_tokens (id, tokenable_type, tokenable_id, name, token, abilities, last_used_at, created_at, updated_at) FROM stdin;
    public          rsyarsi    false    245   �      �          0    16570 	   semesters 
   TABLE DATA           d   COPY public.semesters (id, semestername, semestervalue, active, created_at, updated_at) FROM stdin;
    public          rsyarsi    false    247   �      �          0    16573    specialistgroups 
   TABLE DATA           T   COPY public.specialistgroups (id, name, active, created_at, updated_at) FROM stdin;
    public          rsyarsi    false    248         �          0    16576    specialists 
   TABLE DATA           u   COPY public.specialists (id, specialistname, groupspecialistid, active, created_at, updated_at, simrsid) FROM stdin;
    public          rsyarsi    false    249   U      �          0    16579    students 
   TABLE DATA           �   COPY public.students (id, name, nim, semesterid, specialistid, datein, university, hospitalfrom, hospitalto, active, created_at, updated_at) FROM stdin;
    public          rsyarsi    false    250   �      �          0    16582    trsassesments 
   TABLE DATA             COPY public.trsassesments (id, assesmentgroupid, studentid, lectureid, yearid, semesterid, specialistid, transactiondate, grandotal, assesmenttype, active, created_at, updated_at, idspecialistsimrs, totalbobot, assesmentfinalvalue, lock, datelock, usernamelock, countvisits) FROM stdin;
    public          rsyarsi    false    251   �$      �          0    16599    type_five_trsdetailassesments 
   TABLE DATA           X  COPY public.type_five_trsdetailassesments (id, trsassesmentid, assesmentdetailid, assesmentdescription, transactiondate, assesmentbobotvalue, assesmentscore, active, created_at, updated_at, assementvalue, kodesub, norm, namapasien, nilaitindakan_awal, nilaisikap_awal, nilaitindakan_akhir, nilaisikap_akhir, assesmentvalue_kondite) FROM stdin;
    public          rsyarsi    false    254   \4      �          0    16609    type_four_trsdetailassesments 
   TABLE DATA           �   COPY public.type_four_trsdetailassesments (id, trsassesmentid, assesmentdetailid, assesmentdescription, transactiondate, assesmentskala, assesmentscore, active, created_at, updated_at, assementvalue, kodesub) FROM stdin;
    public          rsyarsi    false    256   +G      �          0    16589 $   type_one_control_trsdetailassesments 
   TABLE DATA           �   COPY public.type_one_control_trsdetailassesments (id, trsassesmentid, assesmentdetailid, assesmentdescription, transactiondate, controlaction, assementvalue, active, created_at, updated_at, kodesub) FROM stdin;
    public          rsyarsi    false    252   c      �          0    16619    type_one_trsdetailassesments 
   TABLE DATA           �   COPY public.type_one_trsdetailassesments (id, trsassesmentid, assesmentdetailid, assesmentdescription, transactiondate, assesmentbobotvalue, assesmentskala, assementscore, active, created_at, updated_at, assementvalue, kodesub) FROM stdin;
    public          rsyarsi    false    258   3d      �          0    16629    type_three_trsdetailassesments 
   TABLE DATA             COPY public.type_three_trsdetailassesments (id, trsassesmentid, assesmentdetailid, assesmentdescription, transactiondate, assesmentskala, assesmentbobotvalue, assesmentvalue, konditevalue, assesmentscore, active, created_at, updated_at, assementvalue, kodesub) FROM stdin;
    public          rsyarsi    false    260   �      �          0    16639    universities 
   TABLE DATA           P   COPY public.universities (id, name, active, created_at, updated_at) FROM stdin;
    public          rsyarsi    false    262   ��      �          0    16643    users 
   TABLE DATA           �   COPY public.users (id, name, role, username, access_token, expired_at, email, email_verified_at, password, remember_token, created_at, updated_at) FROM stdin;
    public          rsyarsi    false    263   3�      �          0    16687    years 
   TABLE DATA           I   COPY public.years (id, name, active, created_at, updated_at) FROM stdin;
    public          rsyarsi    false    272   @      �           0    0    failed_jobs_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.failed_jobs_id_seq', 1, false);
          public          rsyarsi    false    233            �           0    0    migrations_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.migrations_id_seq', 20, true);
          public          rsyarsi    false    242            �           0    0    personal_access_tokens_id_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.personal_access_tokens_id_seq', 1, false);
          public          rsyarsi    false    246            �           2606    16701 $   absencestudents absencestudents_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.absencestudents
    ADD CONSTRAINT absencestudents_pkey PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.absencestudents DROP CONSTRAINT absencestudents_pkey;
       public            rsyarsi    false    216            �           2606    16703 &   assesmentdetails assesmentdetails_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.assesmentdetails
    ADD CONSTRAINT assesmentdetails_pkey PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.assesmentdetails DROP CONSTRAINT assesmentdetails_pkey;
       public            rsyarsi    false    217            �           2606    16705 $   assesmentgroups assesmentgroups_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.assesmentgroups
    ADD CONSTRAINT assesmentgroups_pkey PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.assesmentgroups DROP CONSTRAINT assesmentgroups_pkey;
       public            rsyarsi    false    219            �           2606    16707 ,   assesmentgroupfinals assesmentgroupsubs_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public.assesmentgroupfinals
    ADD CONSTRAINT assesmentgroupsubs_pkey PRIMARY KEY (id);
 V   ALTER TABLE ONLY public.assesmentgroupfinals DROP CONSTRAINT assesmentgroupsubs_pkey;
       public            rsyarsi    false    218            �           2606    16709 *   emrkonservasi_jobs emrkonservasi_jobs_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.emrkonservasi_jobs
    ADD CONSTRAINT emrkonservasi_jobs_pkey PRIMARY KEY (id);
 T   ALTER TABLE ONLY public.emrkonservasi_jobs DROP CONSTRAINT emrkonservasi_jobs_pkey;
       public            rsyarsi    false    220            �           2606    16711 "   emrkonservasis emrkonservasis_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.emrkonservasis
    ADD CONSTRAINT emrkonservasis_pkey PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.emrkonservasis DROP CONSTRAINT emrkonservasis_pkey;
       public            rsyarsi    false    221            �           2606    16713 "   emrortodonsies emrortodonsies_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.emrortodonsies
    ADD CONSTRAINT emrortodonsies_pkey PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.emrortodonsies DROP CONSTRAINT emrortodonsies_pkey;
       public            rsyarsi    false    222            �           2606    16715 @   emrpedodontie_behaviorratings emrpedodontie_behaviorratings_pkey 
   CONSTRAINT     ~   ALTER TABLE ONLY public.emrpedodontie_behaviorratings
    ADD CONSTRAINT emrpedodontie_behaviorratings_pkey PRIMARY KEY (id);
 j   ALTER TABLE ONLY public.emrpedodontie_behaviorratings DROP CONSTRAINT emrpedodontie_behaviorratings_pkey;
       public            rsyarsi    false    223            �           2606    16717 -   emrperiodontie_soaps emrpedodontie_soaps_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public.emrperiodontie_soaps
    ADD CONSTRAINT emrpedodontie_soaps_pkey PRIMARY KEY (id);
 W   ALTER TABLE ONLY public.emrperiodontie_soaps DROP CONSTRAINT emrpedodontie_soaps_pkey;
       public            rsyarsi    false    227            �           2606    16719 8   emrpedodontie_treatmenplans emrpedodontie_treatmens_pkey 
   CONSTRAINT     v   ALTER TABLE ONLY public.emrpedodontie_treatmenplans
    ADD CONSTRAINT emrpedodontie_treatmens_pkey PRIMARY KEY (id);
 b   ALTER TABLE ONLY public.emrpedodontie_treatmenplans DROP CONSTRAINT emrpedodontie_treatmens_pkey;
       public            rsyarsi    false    224            �           2606    16721 5   emrpedodontie_treatmens emrpedodontie_treatmens_pkey1 
   CONSTRAINT     s   ALTER TABLE ONLY public.emrpedodontie_treatmens
    ADD CONSTRAINT emrpedodontie_treatmens_pkey1 PRIMARY KEY (id);
 _   ALTER TABLE ONLY public.emrpedodontie_treatmens DROP CONSTRAINT emrpedodontie_treatmens_pkey1;
       public            rsyarsi    false    225            �           2606    16723 "   emrpedodonties emrpedodonties_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.emrpedodonties
    ADD CONSTRAINT emrpedodonties_pkey PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.emrpedodonties DROP CONSTRAINT emrpedodonties_pkey;
       public            rsyarsi    false    226            �           2606    16725 $   emrperiodonties emrperiodonties_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.emrperiodonties
    ADD CONSTRAINT emrperiodonties_pkey PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.emrperiodonties DROP CONSTRAINT emrperiodonties_pkey;
       public            rsyarsi    false    228            �           2606    16727 6   emrprostodontie_logbooks emrprostodontie_logbooks_pkey 
   CONSTRAINT     t   ALTER TABLE ONLY public.emrprostodontie_logbooks
    ADD CONSTRAINT emrprostodontie_logbooks_pkey PRIMARY KEY (id);
 `   ALTER TABLE ONLY public.emrprostodontie_logbooks DROP CONSTRAINT emrprostodontie_logbooks_pkey;
       public            rsyarsi    false    229            �           2606    16729 &   emrprostodonties emrprostodonties_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.emrprostodonties
    ADD CONSTRAINT emrprostodonties_pkey PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.emrprostodonties DROP CONSTRAINT emrprostodonties_pkey;
       public            rsyarsi    false    230            �           2606    16731 "   emrradiologies emrradiologies_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.emrradiologies
    ADD CONSTRAINT emrradiologies_pkey PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.emrradiologies DROP CONSTRAINT emrradiologies_pkey;
       public            rsyarsi    false    231            �           2606    16733    failed_jobs failed_jobs_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);
 F   ALTER TABLE ONLY public.failed_jobs DROP CONSTRAINT failed_jobs_pkey;
       public            rsyarsi    false    232            �           2606    16735 #   failed_jobs failed_jobs_uuid_unique 
   CONSTRAINT     ^   ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);
 M   ALTER TABLE ONLY public.failed_jobs DROP CONSTRAINT failed_jobs_uuid_unique;
       public            rsyarsi    false    232            �           2606    16737 :   finalassesment_konservasis finalassesment_konservasis_pkey 
   CONSTRAINT     z   ALTER TABLE ONLY public.finalassesment_konservasis
    ADD CONSTRAINT finalassesment_konservasis_pkey PRIMARY KEY (uuid);
 d   ALTER TABLE ONLY public.finalassesment_konservasis DROP CONSTRAINT finalassesment_konservasis_pkey;
       public            rsyarsi    false    234            �           2606    16739 <   finalassesment_orthodonties finalassesment_orthodonties_pkey 
   CONSTRAINT     z   ALTER TABLE ONLY public.finalassesment_orthodonties
    ADD CONSTRAINT finalassesment_orthodonties_pkey PRIMARY KEY (id);
 f   ALTER TABLE ONLY public.finalassesment_orthodonties DROP CONSTRAINT finalassesment_orthodonties_pkey;
       public            rsyarsi    false    235            �           2606    16741 <   finalassesment_periodonties finalassesment_periodonties_pkey 
   CONSTRAINT     z   ALTER TABLE ONLY public.finalassesment_periodonties
    ADD CONSTRAINT finalassesment_periodonties_pkey PRIMARY KEY (id);
 f   ALTER TABLE ONLY public.finalassesment_periodonties DROP CONSTRAINT finalassesment_periodonties_pkey;
       public            rsyarsi    false    236            �           2606    16743 >   finalassesment_prostodonties finalassesment_prostodonties_pkey 
   CONSTRAINT     |   ALTER TABLE ONLY public.finalassesment_prostodonties
    ADD CONSTRAINT finalassesment_prostodonties_pkey PRIMARY KEY (id);
 h   ALTER TABLE ONLY public.finalassesment_prostodonties DROP CONSTRAINT finalassesment_prostodonties_pkey;
       public            rsyarsi    false    237            �           2606    16745 :   finalassesment_radiologies finalassesment_radiologies_pkey 
   CONSTRAINT     z   ALTER TABLE ONLY public.finalassesment_radiologies
    ADD CONSTRAINT finalassesment_radiologies_pkey PRIMARY KEY (uuid);
 d   ALTER TABLE ONLY public.finalassesment_radiologies DROP CONSTRAINT finalassesment_radiologies_pkey;
       public            rsyarsi    false    238            �           2606    16747    hospitals hospitals_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.hospitals
    ADD CONSTRAINT hospitals_pkey PRIMARY KEY (id);
 B   ALTER TABLE ONLY public.hospitals DROP CONSTRAINT hospitals_pkey;
       public            rsyarsi    false    239            �           2606    16749    lectures lectures_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.lectures
    ADD CONSTRAINT lectures_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY public.lectures DROP CONSTRAINT lectures_pkey;
       public            rsyarsi    false    240            �           2606    16751    migrations migrations_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);
 D   ALTER TABLE ONLY public.migrations DROP CONSTRAINT migrations_pkey;
       public            rsyarsi    false    241            �           2606    16753    patients patients_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_pkey PRIMARY KEY (noregistrasi);
 @   ALTER TABLE ONLY public.patients DROP CONSTRAINT patients_pkey;
       public            rsyarsi    false    244            �           2606    16755 2   personal_access_tokens personal_access_tokens_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);
 \   ALTER TABLE ONLY public.personal_access_tokens DROP CONSTRAINT personal_access_tokens_pkey;
       public            rsyarsi    false    245            �           2606    16757 :   personal_access_tokens personal_access_tokens_token_unique 
   CONSTRAINT     v   ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_token_unique UNIQUE (token);
 d   ALTER TABLE ONLY public.personal_access_tokens DROP CONSTRAINT personal_access_tokens_token_unique;
       public            rsyarsi    false    245            �           2606    16759    semesters semesters_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.semesters
    ADD CONSTRAINT semesters_pkey PRIMARY KEY (id);
 B   ALTER TABLE ONLY public.semesters DROP CONSTRAINT semesters_pkey;
       public            rsyarsi    false    247            �           2606    16761 &   specialistgroups specialistgroups_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.specialistgroups
    ADD CONSTRAINT specialistgroups_pkey PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.specialistgroups DROP CONSTRAINT specialistgroups_pkey;
       public            rsyarsi    false    248            �           2606    16763    specialists specialists_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.specialists
    ADD CONSTRAINT specialists_pkey PRIMARY KEY (id);
 F   ALTER TABLE ONLY public.specialists DROP CONSTRAINT specialists_pkey;
       public            rsyarsi    false    249            �           2606    16765    students students_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY public.students DROP CONSTRAINT students_pkey;
       public            rsyarsi    false    250            �           2606    16767     trsassesments trsassesments_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.trsassesments
    ADD CONSTRAINT trsassesments_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.trsassesments DROP CONSTRAINT trsassesments_pkey;
       public            rsyarsi    false    251            �           2606    16769 @   type_five_trsdetailassesments type_five_trsdetailassesments_pkey 
   CONSTRAINT     ~   ALTER TABLE ONLY public.type_five_trsdetailassesments
    ADD CONSTRAINT type_five_trsdetailassesments_pkey PRIMARY KEY (id);
 j   ALTER TABLE ONLY public.type_five_trsdetailassesments DROP CONSTRAINT type_five_trsdetailassesments_pkey;
       public            rsyarsi    false    254            �           2606    16771 @   type_four_trsdetailassesments type_four_trsdetailassesments_pkey 
   CONSTRAINT     ~   ALTER TABLE ONLY public.type_four_trsdetailassesments
    ADD CONSTRAINT type_four_trsdetailassesments_pkey PRIMARY KEY (id);
 j   ALTER TABLE ONLY public.type_four_trsdetailassesments DROP CONSTRAINT type_four_trsdetailassesments_pkey;
       public            rsyarsi    false    256            �           2606    16773 N   type_one_control_trsdetailassesments type_one_control_trsdetailassesments_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.type_one_control_trsdetailassesments
    ADD CONSTRAINT type_one_control_trsdetailassesments_pkey PRIMARY KEY (id);
 x   ALTER TABLE ONLY public.type_one_control_trsdetailassesments DROP CONSTRAINT type_one_control_trsdetailassesments_pkey;
       public            rsyarsi    false    252            �           2606    16775 >   type_one_trsdetailassesments type_one_trsdetailassesments_pkey 
   CONSTRAINT     |   ALTER TABLE ONLY public.type_one_trsdetailassesments
    ADD CONSTRAINT type_one_trsdetailassesments_pkey PRIMARY KEY (id);
 h   ALTER TABLE ONLY public.type_one_trsdetailassesments DROP CONSTRAINT type_one_trsdetailassesments_pkey;
       public            rsyarsi    false    258            �           2606    16777 B   type_three_trsdetailassesments type_three_trsdetailassesments_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.type_three_trsdetailassesments
    ADD CONSTRAINT type_three_trsdetailassesments_pkey PRIMARY KEY (id);
 l   ALTER TABLE ONLY public.type_three_trsdetailassesments DROP CONSTRAINT type_three_trsdetailassesments_pkey;
       public            rsyarsi    false    260            �           2606    16779    universities universities_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.universities
    ADD CONSTRAINT universities_pkey PRIMARY KEY (id);
 H   ALTER TABLE ONLY public.universities DROP CONSTRAINT universities_pkey;
       public            rsyarsi    false    262            �           2606    16781    users users_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
       public            rsyarsi    false    263            �           2606    16783    years years_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.years
    ADD CONSTRAINT years_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.years DROP CONSTRAINT years_pkey;
       public            rsyarsi    false    272            �           1259    16784    password_resets_email_index    INDEX     X   CREATE INDEX password_resets_email_index ON public.password_resets USING btree (email);
 /   DROP INDEX public.password_resets_email_index;
       public            rsyarsi    false    243            �           1259    16785 8   personal_access_tokens_tokenable_type_tokenable_id_index    INDEX     �   CREATE INDEX personal_access_tokens_tokenable_type_tokenable_id_index ON public.personal_access_tokens USING btree (tokenable_type, tokenable_id);
 L   DROP INDEX public.personal_access_tokens_tokenable_type_tokenable_id_index;
       public            rsyarsi    false    245    245            |   �  x���Mr\;�ǷW��
!��� �� ��	9�I�n��]=UQ|G�DS�4r���3��A�u�s�1ԏ�cK7�̻�����]h�L��&=¢ę���|j>K=~�|w|��y���R�充��B���
$����l�+���djc����RJ3bI��zf]���6���R��P��diK���э�J��H�𦱉�ˮ5F�����Շ�l���nJ�H�rŚUk=r���bR�<�A���S�H �ÕON��e�K�PQQy�B��!�fGԶ�[�͂�ws
E#J�e����ʋ�S��;x*��<m7k�VU&��*�"o��=-�C�YZ��vRŅ0��|s��
�GyI|U�^p���>�E6G8��\�Z��x�<��\�E�ʓ�����̠=SZ˓Kzk���,ŝ?˿ܰx�.�R@��S�I)Yd\m�q�y�q��� ��|Ү�1H+���gΧ�Gp��g�նB��`}K���ӏ�f�cntf4�[��!cA�)N1k�p,��#x6L�!e�םf�%gWm���O-��:(���4�\��� (��K�V%�4�QR��Q��&,���V#+"n;|�W��r��t�w)qm�t=)���5l/�X򢻯�d��"��87U�^�{��j/�Q+�^(�7T9���+A.<���$�/�k=���_��J�]l_�ۯ�p���o��ʎ�ת�ʎK���3
�c$�L9����@=�=��0T�94�I�1i���K�4�p������ܹ�U\o���j/��l� g���V�l�(�R�Î�b<����*��:\��^;M�����Z�!����b5w����CT_HY.�u'�|�	�JK9J�'��.�<T�����l+
��
Xk�{X=I�gD`p��3W���?�톽���9m�<�ӕ���1
�>�T=Or}��l����C�A�_��n���J�      }      x��Yo�I�'���� �����]@Y�ݥʣ��V���T$�Av���4��ϻo�������$�gPU}`*��p��������l�:(�tL�TX
M��}�I񪒛e�u5�1�[cڻȢ�%����DQ�L�~��u�K����}���?}�g���b
��̙�Ų�Td��P���Z9����[��i�,h>s��������1*k�Q�Gexh�lΆ�RDhely5�q]/�zZ_v��TQ��12�de:�¢<�Z�23F���ۜ/���ĺ��}��~��U�LLz/�����=`%G[M�h?F��}�X����7�M9��W�؛�	V�`����㬬\�d�rY%K���M� �c�X|�jwv�������|��>�C�8"hlR��yg,K1aBv�J����b��|/:_.Η�O���R}�;V�đ�2۴d^��tM*��}�o�W���rZ݌�.�/��d���!3�y`Q7�S���6�z���q��GUH��_��e�I��G���B&�	�e=(jb�Y�����<�V�j��;N�%)��CS�pa0�C�f�Imb������)��jp��U:{��,��Zߵb��\k�ƕAm)�������:�.^���CA�������*�G5I1��r�s\���p
~���4J�*ReH�m(h(ب�r�ЙR�*K�f��/������F9�I�EZ�>�JX�j��/%Y|�3n��i&��.�� ��8$)�R�(S�d�i�	��+zzǼ��K��4��jc��0������K����N�7B���cFD[��7�����Y�J��y�/Z�K�+<e�C��1�4��7<lxɆt_��(h�T-+8�Fc�|�Y��@��v�8���q��w�e��v(�Fc^��f�{��V��_"�1������DR�VVOV���1r��z����Zao8�"0sfV �Y�Z0i���ؾ�wI$륮 �΁� �xޠ3��N٤`E�h	�zl���B�c������@_+(+�m�8�����a%���B1H��FS\V<�V�B(Z0���� ܔ�6�	ULRv��0Y���
�*%��P=<�ceCeKE^ _�(ԣmu<���g�Ӱ؎�4�eN�En����A��lun�	�E�P��W��W��\s�̈́A
�1�:�`e,��8��D�uͪ�^��F��	6hV�n�-o�U`�\-�ǹ�xtG�N��%g��ljk6	/d[�[�S�φ	��Xs���fJr�*���ŏ���2UUiA@R�p�<t3Eq�m�8i��'���Zn��;Q�pG?��\;;�!O��/J�p~p�ː(�#���h���������(pj�֬��M8�C�<�V�܊�8�p��$����V"���	��"��
+�T
sIQ_X�0h���C���x[����SY*����,�ʄ�P���-y��v�TD�����BU���j=���m5dO�Yi0:͒S���K�*8Y� -�����X���h�Xc�,���U5�0����x[|��'A�N�7����s���X[m# q�У����H����ۤ���)8�V7##�I0Y-N^U�a���.5z�f5�4 T�JTK�)Y`��l�Ue{���&J+ ��Aj� ϳ�w�c㕮���Տ��&��I7��Z L)��X�q �C��?�VG�n�
���.��\��^b!z��'�j�eҥ�p�(��]��-�5. \l��d�y��n�g�gY��@�-)�G�R'���12���^���5��d�#�<��\��y��6rt.�C�=K��)c-xw'�1R�n�m��V���0��~o���Su�-���p����THQi+4��L�Ւ^��2��c�E���X��\
iX,��]�Ɉ㨒|�������jm����TBuAe5_��j����
��sR,�Bbh�X�ToǓ��>�VG- D<s%@
�T����4R������j��<0U �v�V\�m�tPJ}��l��64Up�[&�7�C+����eÁ�f0�H���Uө��gU�����D;�V�m4�������:Q�^������u���jҚ�C� <�Ģ��PR�T��@Ac�i�3�t�V�[r���v��܂�ى��]�"�c|����	H20�8T`�U�r�3{��O[1�������d(��s�����(?�� ������8D_8D]pl�s�������O��+m��c��	mZ��2[�em�]�$�|��-d��Ηuӏ�藴�a����ڰ@7���@��3*�����9��xH8���"�Qd�!��6	=�e������[b\�9 BVK��B�YR�2UQ��M��&ҋd4�sBAO�Ff�UV�RŐ������&�y�|�f��ӠK0�;�$!,BQ��ѵ�M�nAG�Sf}���C��؎h��@Q�Q��3�%��Ji�)у���	����K�� ���i�Y�}�J��kf�}�J�J��<���ray��psY�H��ʃL��o~�_�����&��uϲ�;`�9������9l��´h�Pbpu��� \�F,I~X�ſ������xq��>��fE����������kz�bñ0��E�� �$z[��zP\j�W�{No��V7|��0e��Ӏ���p17@���Z�Dsc����l۸ٳ���kps^���7]�\�=~�q���|����//绳ݚ�����+��W/��}9����}9_�Ϸuy���{�9l��{Iפ@�t5)(��)�[��h��r�ϰۂ�a
���+��U&ғ9�Ѐ��!䘥�e�;�i�[��yZ7��$���������\:�˸X�κ*�������%���xA<e��[�'��wn�r7I�zi�t́ZJ<��n��M��DJ�M�؏Gڭw��M�~�����������h����a�x�
�r�dT,B{�\c5��N����ͮ�����R��2=�i=K�!:Y�,fv�:Hh[�,� (����>�V��
zɋ1�B�X�K]�����?��4.:�j'�t/�{-4JhT��4��<(�f�$�Q��1B��������-�����+v��D��nvq�a��u9��A"!N[z�b���g���)nK��,�t�Ï�  ��y���҈b�e
1�0������){P���������St1_l~�{��l��x9Oqq�We�v�k]���Q�]�VP\���RoD���b�t_b\ ��Ԥ��2�Lb��Vﻍ�~�KE�����Gx��q�f/�g�����ߏ�>#5��\T����ӆ�-��L�S)��w�b�О��7^��0�3G�i9�Daʩ��0�e��')�LZ�V��5G�/!Û������[�7����y=ݜ�_��A��u��f��q��O�{���G��u?��2_A�H%��q�ɥy�A0Ab��b������g����&��_t{�&��o��Y$�0�lf.���Hq�p��:=/��mv����?�B���4��H��;�Ú�Z�=�&��
�}s
���?c�"ٷ��w=˦Y _��h��[�,
@�J+�JH�����o�v�����ś��@<�z`e!0��M���W4p�+�AP
 ���u4��J=F��A�WR�\�K��O�M��)*8/�
���a	� +����!��g����#ɪ%��D�%�֖�H���l����1��gd]���b9Qw�n*[���l���.�DxC)�<d�t܏QnPw���EZ��Pi�#���N�:�Z��h�+�e�np���<����x�Yp�a%}R-%vg��N3�ZպI5H� }�E�t����lk���D�4��J����^ûOI(��B��j!?�!��v
�)�$�B�b|�~��[�U&�(�u�R�8� $Du'��,⇴[F8�?��Gd�7�&j�AR��H�(E@Ru��}��Ta� m�m]+p�����M�P^�XRr�N/D�`�k&�����v    Qy/}�88:3'��pO�NS�5��A*����ۏ��6����n},��5X�=� ����0ѐɤ��F��ĵ�U�Y9v_e%;|Fު�i�RX�X���A�܍E+Z��~�:���MϼO�	  ��b�{ ǬQ8n�t͍Bq�-���"�!���^A����H��LK* �A�c ��	J:".w�X�,~�R`|�7���;�K��R��*�;�b�%h�����b�I~(i����˘��f�8�?|w'��m�F��5e�Iyٱ�V���Q��4�k
���d ��!���)��.J����1�4�[i�~��rq?����,y1 ����NeTa�,��F$�A�"��D��5�)@�{���K���\��%���B[0�7I�71���q4A���c�Dxi�ʗ�+�A*��6����p��s�iz ��IWLͩ��=�Ñ��DQ�)!堒KzT��MK܇�'uIQ£�"�,R0
X���J���Z�rm��u�W[l��zTfQ�/)�y*Q�B����;��7��Q���#@�0���K&^RT�jAl�ڤ���G���.]�ď{Z'��(��b)�Fye8(�܏�`�H�plxe����K:N9KM*��pn��#�2�p�S�j4Zvh��l�E�S8c��Խ E8�M&5����<�9u��v (�Ƭ)�F�FA��1{U[5Ʒ�������� ���#g��K��-���n7�-'h��g@��xJ�n�P���:^G`9H�syl��8&������s��S�uH�$.�����V����Kr&���^��E_<���'������q���gw��TQ)a�GJ�v�d�b��TMa�o�u��눫;���/q�.$+���|#��rB������띋!PN tg���,�SI 
�U�F��Ǟ@F�������@'�~�*����m>$��!�
&�H�sy ���Ф9,�3��1�z>�bٽ�C1�l<�͏ԛD'��4���Xۜ,r�;{7�^l=LY��E�(-����<�'�b)�Z+Ԍ�P��-p���Zvk��xP����Ș�}�{���>�%a��X��]��P�f$@���~�jp����~��|گ;Ӯ�
�K���VҙQ�kmK���dS�E�A2{d�s
njc�Hy��h�b���0�Un9���E�ꡚ��>0�q����d�]9D����X�[�wTs�̵��܌.^Y�(�d���1�*��p��G�D�,���������^i��cT�ُS��R���hsqR�����H�R� ĭ"2A�S2؜fTV���QNPޝ6j9�V�g(a+0�L\%�vS�#�%ح��E�����>�HV�T"C" �S������A�7Z�}d'�x7�=�t)ΥiVӝP$W�%Up���XX*����>�n�Sf �	~ErHY&+S��Pn����>��B�(��3C9.��"扼򨳅�Օ�3]ٗ8
2<H7�4 M��J��2��(K�+ ��3��J�e��2��#0$݅*OyJ0C5�&	��A��c������J�='��N�ܗ���������JE���#�oj��T��2a`����w������_��a��7?��w�����~����|@���g����$�8՜����(���Ͷ�#=X{7�&S����}�W^�SkT=�՟J� L��P�v��23��C7�6S"PY\z���}fֺ��n����'2QZ��~O$k��~�������T�Z\ ��*E#U+N�6�$�_�I���BV,�,�q��Ń)��P-�'Tq���Ͱ�/�| ��$�.8��MYF	���7	L�nNRdu��o��f�՜2d�мe��>��i��0�gR�q\�I�s��R±�7����������p(h�p��Kx!�~Y*a|�j�`Ow��ˀ�oqy���;�����T�4F4<%�h�Y.�����oKWw�=��*�4��bΟܫ��
��(��H��0��ץ(3��n��C8��p�F�+�o	�j��Vj%E�`>�˯5C#�����t�n ��48o�{������4��|����W>+��M`��Ȁ[�(��5�u"���(�;Z�a�/����_�u�:3���v���[��W/��|{N��Aj��)[su��g���/�&��ܝ~����������6��������=���`_R�8��}�����nr�� ,�S�4����������f��n��G��e���}2>����0'SЏt�)�𭮓t�o/mF�J������V�?��x���Q�RL�P�P$k�}ΎK.Rc�>��{��Q]��^fc��ª�J���d�J�nw��Q`Ȭ~�g\Og��v�AI�-��y�5.�1-딐���꧷]��j�D����B�KK�f�K	��n'g����{1y�������?������wbJ���)U_�ꮸ��@,�;�Y*ULdj^��~4��.g��w,��[�C�>��G���{�Q��s��w����`H{���H¼Y�3�(�{͜~�t4�� *>�	j���I�텇_�2��A�A�q��j���a�Y�W'oS�8���?�/��.a���v�vVNܻq�/y��g6 ͕2�$�P���_1N�<eƞ�?
4C�c�~�r���]?"�"����J$.�O/]N���b��g��Q?�,��ÿ�̦po$�õ �rKo)2<Ъ4�d7S�KS�s�;�c�,�
ϭ��Em��ߞn�.�����=�`J�6��1�ԓГYPײ��ձ���S
������8%;��X�t�v��Mfo2��'ޒ�Z�_(��>�ˋ���'���\=�v^+M(��kp<O�s��^�(�Z`��:�E/�$hR7��q��Z��u`-�Q��
)��%�S�Ψ1o$�m��)�_���~MA�+ɟh?��5��♿�V���P���4]�)a�T�zy=/L	�sK@���5��wY`�D\S�9�E�w�2F`�ޠ��A���Z����Ff�fWv[ֿ�E�����#��ٛ���̻H���Ы��ښ"?(��w7t��}������}��>L���а �bIC���;8�������40h'+���W�.���!1=��[�AM�6�Q�p��K�b��b|hF�B���PQ�Tx^�-���g�=y���蹸��g)PC�Y�T�LG1�@��U%jo����l��ڗ�;�ދ�Z����6;wӡ4����GR�U%�� �F��
EQ[3�k#S�$s"pJ�#�L?Pw�=AU$!I��t�
%� xZ��!Ga�Y����!�0Uk��R��¤zCh�w	o���c�|�sI�yZ.�iW'P�JD��z`�FU"U8��}T� 
�C�ʠH��(N'$���\�@�q�O�4�~�R6Y�1B����@�b��vW�{Ɲ������f�M�;�9�p)K�A{j	6���!���k�ߞ�3�i����fm9�I��'ق񃪅*�n�!!�o~�.�@E�F�c8�>{`Ga9� !�J"N���q������9y�CAw[��/5�(�Uɫ�T�=D����)r6J����R�1E�Ǡ)�8�Z��d�	�&Y`��4-��Y�|���t�4�#JRiMvj��#5���^WM�Mfluj+�����Q���V�:C�op*�~�Q�K�"B���J��VW�o��s��[s8o]��"tӉ�F���q"%8�<��
("Ofh�xy��e7������tk1�>�^t~�z 舝���W��C��u�|�Z{n��UN�n���Q�%�r#��~�/�JZ짷�<u(���3:O�8�k�Ɠ���[��~�/ F��?}�Bg%�q��?IIj�Ѹ�Y
N��z7
2�u�a��e��	�VE
�����)E9��r_B�A�bU ��.��<�y�e�/����"j��������Jv�2�i���bII'�e)���2�T���S����Ǟ�C�E3O9�Q4�̃�q��w��O�xJ��n�>�k���w ���q@�D󛚕�p�ԩ�ːՙeuΕ:,��Ge�4��P�����    �Ae��>ɺ?�n� �c��u4�.J"�=��;*cU�d�/CV�V�h�'�7�"R u]��:�B��R�d�:9�l�K��F@a�%���POJO]�݋[J�G)�_��γJ�Ѥ�`<i��l �+9�(&Rv#�R�X�(�s�X.�O.�|�*D���(�
��z����`�'kT�>��Λ�5�:E�LSZ~�~	��U���t�rr�(��0�ujNT�����ボJ2s+L�7��T&-)�ʫN5Q��A���m�Zф	n�T���� �o9����βhM��؝0k��,@g�cF���@���UϼԁRF�oT��������Є�"�&�V��y��ӫx�W��<� ���./q�Nq��jY���lag��W2�ޓSR�Ng�h��X�l���Z�(V�P|ٲ��j�E�n������z�ep�9�)  *�Ϛ��w�
��KcT��a������d�&���Hy[Զ�碩8����#��vy������I�7��:� (���? ����D��0j�O��I2R翔�^-q���v+�
W�x�	�^�թ�]����Y����h�ߙ<:N�4���a2o���}&P�ƈ�轼�����������UVW�[�a��#�����]�_�Mw���} �s�3�� ��@��XM�gYK�NG03�p�ݯ~����x1QzuM_�:��+^|��,K*7��F��� SI$�-W����p���F&��1�!M�:��"�<G����h����z]���=A���ɋY�<՛���������S�!��Z�Mm >����-8�2�'�Dظ9(t�ln4�7y.�M���-}�o�'`Em�q),�btԌ�3	ߍF�.ݿۇSPɑB�Y�J%4�$V}�7�4��>)H��w�<<�f�������O��.�G��y��w��n�G��Η=��:i8d�|����4)El'5z�~�0�J�DKS��M>��4�qoQ�Nj<@$<�Hs��Ձj�(��X+(�>�J�~0��0��xRErV�
��҈��#�]m�3�
I�o�''Q�<�H-CI(��ǥ[�LɄ~%��0��2���<�R������C�K`?��>Ը�f^B�0�S�K&�\���va��c��%0�5]�`c������_�	����j��/����!�LJK;rY)AYu]#����x\�a�ϩ���D�u�@���.Wp2���@׬C�`h#�&2�S�yv覦J=V�֕�"�KQ�?�K���=�Ëqy��xN�f�A ͚�b\aS|:�:���<e�^�`�U���������[߃�����7P�@B¶�aH�=�� �銴O�#���;�k��5<6I�B���iN�it��!��fR+�{v�Q�K3�h�CE9��3R��(jIeLs"�A��ou
n��k9�?á��~���bi�y$���RMBF��A<��݈\��0�T�'hb&�}�}�(�J<���C�OP��%J�Iķ�����2n�h��p4,<d���e�x��j4F�P��C�/�P�n��S���۞H�5�z���?O^:�J��1���/���^r6�6�oN׻�����G��F%Yic��
�R�H�Bz��Ѳ�\}4��������DD���^��P#��6�Z[o���g�Ҫ�ρZC��sD��Mip�L��S2��8㱧E���ڭ	��Ƶ�N<�S�s��z���X�D/�E�VxU���,/?s.f���������j����k��J��i�Y��Y[\�zluu��^��衢*�����*Z�TclJ�T�V�W����k�r �~��CMDTb�G�iْ�^'M$���a)�>�#�5�/ )�C����+���bs_6�8|�3�]��yf%%�Y��#yax�X�6�2�:��M��/o�6�d1w�rI�;�
:^| �rM��A���+s��D�\��K��:>F��}��:�R>)R�,�_�/qMv�@�iB��LH:���~3���[�5)�#PϾ�	=-�Jw�����g_(�������i�J�r,� VLE���,j�2�aG��A!��ȇ��o��Q����3��cMQu��*-pO4tw��+�+	5f(�Sapl+GIy�旀^4Z|�*�45�/'-T�"������*��*���n�I�?O��N^�2Gf=�(�gu�V14yTIe7F��vn��y��������<U�,%�P��`���&�e楦,��Ě)�}����倄 W��USiO���~�Y�%[5F��R!����Zܕx��nbϾ:h�{1Ld�����T���]��fT�bl�z�H{�����r 3RSÙ�(��$�-��5�s#��~����D,�$��@�C§�f8��ｅr��D�1b��h����]q��f�'��|e2_�F���% 7�4(�^�w@)�J�����5IAB��L�x,EZ�� SQU���f~�-��װ���e�%%��,U@hr[�TxB�(bJʚ�-D��9�n]�V���%�fsh�hU�)�C�E;���}P�~����+C���A:`}�lS>�/Vi��<3�w�H��^j���$N��		P���(ϥI3Ny��Iq�)��zy<�84rⰍ���?��njƴo������c鿇?�YJ5;u)%��,����.�Xn�蕳��_�adӲO'/&����M�2�O�8&T�8��#O�~^�x:���#�ƨ�($�K� Q��ԍD9QP�cN�X螓���sO'PĚm�0b�SW!h�+��6��d�Z�LA<�Wþ��:�yj�#�!`�H���e����u=���O�W�g��+j�A��ӐC�QL�z:����-.u�a���l��r�D�p��}19����׷?��a���o�{��?̿��?��n�>��3]�Ʉ����N��-i����Vx���v�n6�6������|u=�b}�j��ѯ(YzsJc	�gq�#P�~�O�������򇏋M]�x9O����k�*��y�]��,:���})�գ������(�������0����\������_���A�b5����]L�R7�s)��r�Ϸ�s�E����u��g��/���,����U	���F��N��[Uh:��i��`v@���l��E�*���+5:��CW�iA�ms����	�~�F�������T�,α9 ��I��Y�sm��%�+��li��^�//K�<_/�y/�h�گuMSl�/8����c����t���:%��uvL�n�� S�\C�J�Vu�b��~����U�R4����d��*���`K̹��*�q~ �iYa5 ]$o83�����#xz6��X��U^��W[���y��L�ek��JJ�ޏ �,Ta8Q;�ǘrP�4��k����$��Of}ܣ�+��弿�?�K{ך
O��|��[#���?~��?�{�����۟�������~��7�߽�w������}��-������/�5] �J0ޛF�Ujh*L�;�{Ō1�,�~�4#�bG���=�8�������f|X�3�7�/Y���ߠ�{������?._q�/�������H�W㭎^�H��)�����1c#6��r㭺��~����?�V�C;ES[�����;W����Z���;A�٩^�Q�|�V.O�FS��K?��'�VF	���	��Jsm��`��$�,�L)9�sۈ���W�z�ɼ{z80��`��b/o����/)*5�Y˂���f�Y��՘��h<l�7H��̢׹��|<a����oq	H�^��J��8?������� �������7s1�c���yN/��X��Hҋ��K��ˏN���ʢ��n(	�L	C�� �Z �VI�k�+�cf�:�B�ͮ���`,yYSG�A�!]D���w�Op��:2 %������KXzy|�����ۋ�Ԃ�<��y�����%N������OkC��7 �(�D	�+Ϭ�z�*�n�&�٤T�6Τ��dFY)��X�t�3zu-���|:�c�h����:�� ᳿��x���6��'�s��TS'�    Vn��#[��F��7���<}se�����jG��;���l���B�ة�>`I�;���2����qgdF=r7Z�5��)�:�¼�V�Q{oRu>�A����BC���]�I|'�I�Bֱ��m��n�'Y��)t{�ܓu��ǭ%%�|f�RRPщ%M�5"�2YJ�壦�[ʶ���������� Q�C��_��~�?�d�ُ߽�v�����?�)��q�P�R^��
Tx��5Rjn���i��
Z/uλ/C�n��a8�.��S���ؠ��R��H5"4Y���2Im�#�J���������N��)C���4�9�U�@���C��7�~�ӟ��~�%�}{CBo�_�yxc�����GOŎC�|Uo d�s|u"*��4�u�:�C�7�؛û�����91>(/�q��ԏ��O#mO=�Z@Q9FL.�����O F�+���q���ABUT/�gR%j�\���}S����􏥤5j�]S�h�K�⼰��-��*M��j.��/�g��#�9�xH�_3���V80��	ƫr���0�t�)v����&�^�-0�Y�`aj��H-V��t4D����ݙ ��(ߩP�^��4 ����7&u�}�7��/��&�Y��Z
G-G8u|�ـ5m�6f�>A��ṫ����E5u�
t/
�P��4�J`[DW#��/U��'�UI���z-j�p�m�L
'm����KU�m�
�9���S�-;��*����o�/�_��^���FS[�,X��E�n�pj�3�~�=�{2����P�4ŎrN\�Lp�1�+�6��a��Cxkg��!��Y����	6����..�8�>���"�@W�^Y��JW�@�*��� ðx��aBF��D��r�q:�5R.��T�f�\4J�̔�ʚ���'?�9�>}���%Ϫb�f��k@�4�����mQ�"f_����c�=� ?#�k/$�c��T���	0TՔC��9=�����<`�n�M��k�),KK�Ab�t�q�=H̕E�s���>��`*����zq�He��@8��WX��zKil� ����D�V$o�Y��P�c��&��*O����Q	7cК8�Ԧ9TJ�b��
h�`Ge��f,S�o���4�1�i�S��j%�V?�P�������┪��z�SJX�Z�al�c�X
R��R��㋇ ڢ��)+1v*�4c9T���ԝ-��Zð�EJ�t�~�,>ތ��`>.��H�6B�x-MX.[���?ٌY(��5���b��/F^!ur����1O]b9���#G���v҄�l�`K�� �k�,�W�h �$����fL
-2��=�C%	�&�K�����1Zz}T��8���'}e@�o>�ī�ú������_�b�x9�d�"��M��pڏl�¬�Bf��b�Kzyi��aO�?����X�ۺ��@zW���?��Ūn6/�#}I��+6ׯ(�Rۂ��4j�|z��W���.nw�[-�hɿ��)N�(���}.9�|N�m_��[y~X)�5�Y,oP����:7W��2A�bb�i�x��g84񋋩��ņ6ks�������E�_�u�}Xy�(�޷|�K���s�c��u�|��"�)[�=F�ܭ�Eо=�|?���~���v���Ⱦ�����QҴ�K��/������҇d\�S�$���'^�u�{�h�W�+z��tAr���e7�->k�%�s�<���ϝ/��@r��g�X���/�>�8��zq�qK����������z�}�T��J_��I�:חb���a��4�j͵0��Ϡ�%�
��/:��ŏ���8��+���������\ҁ�w~ڣ�����/��Y��L�y�t
p&{e^�fT����v1���Ӵ���m�V:5�I_O��b��x05�s�s�(�i���v�p���І�S'�1������k�4M�_@H�N��x�Z�T�1{`�����ʦW��#��}�9��\*��@�����Y8�\D�C!�D���Mʝn�;�}��3h�c\O��WI{����g]P�k�p�ls -s��ʣ���\�V�i�՜jo{ԃб�o�8�¸%,ɥÁ��E�� ���R�U�^�con><�� @<-�}��mߒ�y�S߷�*��肊�+M�|��T���%����|Ƌ�*�ow�^,����/I��y��Sgg/��ҡ^�A��*v����^�f��2���u����(�$���^|��]���?=�C	_�����sd͍���%{�M�(ai�C�&��n���.���{����?�����l�������}�lK�:e�(~�YJ���N�A�?���r��_l+�v9	2,dO�$��������ky�;��uﭱ��Q�,����9Y��d��.�M	�پ>���-���b���p����g4�w2����@�#'�5!�n��Iܼ��b�X��j������eM��n��mH�oݬ��_j��r��o7��L�������K�k���~�U�p��Mil�P�������2$o���ۉ9�-��?<g-��f�[Ȑ��a^NA��Ƌ4&��nN�o�Э߁�S+z�k��a�d�_Ѭ���g�� �z�{����W�^�����Ѿ����i�Im=�۰�iK�Z���7��o�f��65o�z5���{P�($�]i:PY���A4^��X{���l�\��5!�k��29Y��b�fjj�̣�z!!�r����x��(�H���M���1=g�g�5�bGyrD�&|X�?
���ְ�k�z�1
����$c+h�u��^y`2�VR�A����RvI}��,�&a(�~��N"��/b�KT�Ͳ��*T��!
�s�\E��c"X\�$�(�Y��@�^)��gg����dF��S#X�S;N3Nc��?E@[��x*��A������p��ɉ�7CTS�-@�I�=6\k����(!@�zE�����Z�6<5����˰*]P��<����Z���-�N��\9Zy��IO��`��/�e6X
�h��Ggz|F����@k(�I#we>�PT��j�hy\���!F��Jf�u(g:T����Ȫ��Z��<����ZRq�u3��;j:�H��ʫTe�G�y|.);�{���ixh`Qi�3`���j'ƨ9"��sg���5༠�Q�F.�ޠ�N����9H�x��(� =�T �9u�(21�#9h_uT��ebo��r�{vc���l!��h\{<X���p���b_�"K�2�|�{"鄲����Wc%�Sf$%YN:V�	%6�Zq�
����YmR�g����B=E+ˡ��A�Q�p��X�W�Yќ�K]��/ ���w��RUUi:������;uD7Ʀ��t��'c�vYE&d"z������T*�G����$I��&Z8��z�O����g��� Ma�ŧ�s�=����ld+F�/ ,`T�J�Jp�Q
��<�FMB���-_$�#q�T��ǝ5�ް�y-��Z�N1F����)����J30�-�[I0*<hQph���ex8��4f�d��J|�T�6� Wq��/��QᮘZ%f��Zf�w5P�@��<n�$4)sV�Q���C�S�[gz7�4*�Gdxd����3�m�hB�o>`^�!D�9��f,P\�W5���%J��p4��TH�[��D�l)i�JX�s�e
�kVpZ�PN��:ڌ%8�\aǥ�FU�$�F��K�9�b��&�f���+���z���*N���'�1� ��em��$��+^`6�Ge�Hy��>�^��{.���<�V��JAW���Ewh���Ԡ���e,n����1cJ�>��U�{�w��(���S�5���P���W��p��2<�����2<>����R�t\s-�Fn�I;���n��T����Q�A��$���Qz�S�d�oJS<]�HqH�$�龕Z��@FH��Ǎ)����&>@K*(I�Q�`z���FK����O�J�{�"���I�!Kc5���/c'���C��r%����    ��3F�zr3�U����_��-�3��8X��rҥԨ��i��ė#2@���7�.�4�����s�Q)x<��-��'��d�񈕂���{T��K�@��i0��#?���Q�\D�)y5��*�b�ʝ�S����1�Mr���h"�QA�cِo�
��Q�x|�����'��V�e)�5�)�L�٪��5Rc�ey���Mr�;KWk��ɒ5C3���%/B�*>�_'�%�$���,id#���|�.7��(0�k$���c�6QQ�Hj���=_R��H>�?�.�E�4��PKdhba)�T �	M�`G=����F�q��RJȈg�1��Gs�5b�#�x�+��H&�-��[c�+D��`����j�ֶ�|�D�+�%4I��(E4G��y`��M�.=D ��4T��Aē&�*Π���ml�����5K7��_��8G����n4A��Xʰآ��aL�4�UUks��%�� ��3�"M;��$���̅b�'h�t��#54���V��Yb���}�>W5W8��E-����e�|u2���-bv;Vy����E�Iᡷ�4�fMQ�����(r�'@�ǒC�<�HMG,��uQJ�4eb��0{O��t
�=��L���f��061B�h>&���epo���}aŃ��g԰�qQ�	U�e�6�p]G�|��e냔�u*R����d�l�������1��h����hL��~&�t� �0��ٱՏ���U� �����:�$*�u*#B������غJ��0a���M�g|��Q�*�**�Z�h[�S�EW�n삅Z�4�7�J�n�8��eզ>I�H�.P8��2K-�>�A�d[�U���c<�B!7��P$���d����Q�ĄN��$�EC�āH��ĩ�A���$�%�%�x�8��-�}s�E�|�4[xh�c�@��с��S�UT�RIIYhc�x��8��?����B�q�t�񶘱ŏQ�Emau���ҥ@�X+�¨s��(�V1�*#��@Up�}��	�L*�m�$�<��*��T���g�:M�T*il�ϕ���L����k�$��קߘd��6ۚ�Vw *U���DXSSB��Zm��&�j�h1�/gc�h�~yi:���iL�bUH��|�;.�8��K���7��;Lя[�8��ZYVT��]��o ��s*,�pM�=������A�=J��p��}e�W�[v�n�Ιd�-Mk�a-�8,e��zH�2~$�/��O7���~��]㹱5�Z��;3O�����u��m=]ѝ�uT4F߮o�|�E���!^���	ZMT�@�\�e�A�Uj;ƙ['��e��}������r��h���M�f�ؽ�˫F�$t�<�Y淪�92$F�#��
����N���Lc��r��W5��gb�Z/��9��Z�$�>�/QbLl�0R�I�}P�tL�Ԕ�ʹ1Z`�i�].���G���E�qY5�<5�+��Eie�cȃ�Xo�[j�O@n�u�q%�-Ԗ�;o�8^v�m>�*�;X�X�N�i�b��
�m���\�6֓H��fO�@��78^���\����������N?���ƭ����a:��X�p�wE���c��g?�m��1����.�:o�Ĕ���X��R���	g��h>,�H��m�"�5ߋÇ���:O�S������d��{�*����z<��fˊm&O8�y C�:�F9~8��`�loZ��D__��<%��� 8����	NS�T����P^ �C���F/MJ4t�K^� *i����h�[�sL�XƷ���,����Ŗ���Q���BF-b5Jl'GX�ƪU��K�na,u�}S-��Z5��
��rV*QcT������F��1�B=XAh�*>�ml���rL){zec�
�3��C�X�0�^3�v��~��'V6ҭ���S���-ՁZVb
a�1B�T��u�}���zM���n������2��$�a�u5�T۪�
�ǖ:x�n�l|$->��Fşt��Y��N?:Y��`0�غF�	n�&��B�X���ap�L��@5q�O'gS7��ɣ���ޕ
�R	����a�|'p�a�E�QU)�Ak%�KC�ZM,h���Y�W�;���>;�y
4���f��cK����$�yTe=��ʝ��\{�9����*pˍq��QG���MM���
�p��@:��5��8(���ku����Q�pMI�p��RV�l6�j�h�M�����?�C����� LщGmG��S/�a!� ������f��hT�����_<݊;�l���0�B�(�a�ehP�F�bO����GO2(� i���x��2p���r�/�Έ�i=Kq��o��$ܞv���ޘ~���]e��3��*�ވ)�xG 5�h�G��H��$�
2 ,�G����3Ҍ��[�)�H#�iF�E��U�o��8j0���f�I��o$��2XJ���,�Tm�j0�ʔy�ТY������{H�TQj4E��Kэ9��(*dŹrZ�ѐ�N��>�7���!�:8�|���B6�C��c�=�J�:����b_�����Ha��_I�*���%P0D�#}��Ȕ���[KE�lO�+�Y��Lr�%��B�v��\����Y:_��ʋ�����%�U��Ө�0[�ڸY��465JeO��u^�*��`������~p���a~=ٻ�����G=v��#ݕh��p��B�*��5�]��=�������������Ŷ_r�h�f_o���<MW�w]pHے�EPg���U	���4I�>X���L��o>	�_�������we��ݓ��!O/��n\g\L7?V����R{�!�O�#�pҼw��<F%�I�	��R`Q�א4����ŁA˺�����7����^����w9��br��|B:t;T 3�����%����~��K�58aTU�z_����F�HN7�w	QVV�|�s������I'�[����JY����FD�'���5uRR�25l���I~eg�it�@H���j���f�:?!#lP6f�Z��(�a�xӢ-�A~|�PL.��t� h��p���?Bu��-�Ð੡�J�~)<���`�&&K�%� ���>>é��@4���{�kD�JV���8�b��OŴ�g���񍆚��
 6x��2ʈ��d
�C�pn�w �c$�T��k��A�pL(�_D�n�"�D� ��Yi���� v>"���\+���(��k11^+0����AG�T+N�<@GY�S[3��:���W�}Y����]\q*3��h���ϥBGÄ�pT��0�K3hg:U$͐K��,�J�Vw�_��PL}X �O7m�A1�j3V�q&x���g��j%�!��Ӆ�oT�AC��\���,BP��PW��a�V��EeY��9�����{T����#T�Y.�]3�C�"�\D��(�3��w��'}��%�S�?9\ͅ~#�守��pǝ��eڛ��ǅ�T�Y����;D���^��������p�V.�]D_m���s�)G�#a�)�A�lU�1		K8F��e��z��%u)!T�:'�z$�p��RK4R�"q����%Z��h��h4�r�Ǝ�;m�U�S�_��ؐ�
�E<�~o�6�-I�94� )渉�[�D�c�[X�}�>�0i�;>S�O^�L�潏�����(���d��I]3u;m��@���9����C��w��6�2�0K�45���Y���-�e[����LGF�	I��[��.8Ie�D?�8���\�0o�4��w��Y��K�?����H�$�\��z�:��>�a	��j�Ӑ4oz���b� ɚ����eV�w�1�4@K�.fy��n�n�"*UA�}�lU�$պd�O]t�b��M�I�<o�$_\q�{�'5+,��)�e�~�	½,)��d���VI���~��9ٝ�bI��վL���}�`�f�26��;��fY��k�!��:n�`E�����1�z��ƖH�� �  ��dd��1r���Ǝ��}p���2`���9�ݗ��jw6� �'�"�Ά����K))�cq�<�n	KT�mZԈ�CK��_ӧt�Ghg�zGP�i0���']���{^J8Y@^�C��icS�F�>l�C�X�x>H<6#��|�(�f��V6�5]"�0���ܟfΦ��~<�Bk$�^c��D�IXӁBj"x�Z�>DT��a1L�Yxp�WQ@����	�O ߨW�޽Ϟ4���_����������4ϖ�>f�zd���z4,�����	�qWT���$N�5�˂T��VQ�Y�	2oICƩ����'�4MN	IL��
x�#Y�ƀ���9b�*���WG��c��3%�f{~��tD_Q6�<kX�\n�l����WB���+��x�-�(o g�5J�VV���ػ��w�ė5`^Y��{�=�#��f���R'��4i]#�8HdcV8���A�����G,w���h��ύ�Ck�[�e�b������!N�@�U��똵�������J�9T�����C�ا%} ��PgAw(�4G����E�YH	<w5��/���>z��!g#��I���B����Tk�@�<fC�<�ڒ"���o���m`D����4�x�}h��@D^��ԉ	��6l���OE+����4��o_�d���f�qV��6�0�ƎLA&-Ǭw�G��1�����O�Ta[�"�@mAy�5�1c��?5� 9UK�5��(yda��6K�ݘU�������j{֣z�u���Ҟ�z�Λ�R{�� �ױ�������.�����Q�H�z=o~�؊X����X�n6,� @ȲjlY��cƺ�p���
a)1I9�0��Ի�!�^+P�p�5W�d*����H�J'�4M'cz�y������>~�Gu�	�$sK��Q�R�Q݌��.�������c�aRdɫ+�
	 �Ӥ�|O^N.F�.(l�,(�rUL��I����&�^#fV���I}��Pf��ph�@���	���ẑ���B�+����`��]�ӓ͟�媺����ڝ<%A�^u�"�1��t���mN/��~�^0�藐�9W=u����b2qr�J�����1���/�7�m�� ��x{�k'I#Wb��(< r1U�:Xn!Q>cp&͊�;��/�y��~�~��s���^=Ғ����u��S+��2e��0�x6�8�4���ݯ�w3��'�ػ����_�േ�Ĕ����u�Uo��N�⭫
	ZX�.|���e���mt���5V6�癰ax+��9I5��]ŰQ����Q��{�B��p̜o�m��-�X&?��T���/��c.�;��,��ms�n�{����܍���TO��{�E� ��p��T��1+���8�b��)�{��:� &�R�2��{�?j�)P\���Ô�EN��耆��\����wb��y"�-��_��m��W�:u���ۡ�)(��&���ZMc�|�}���T_�h��
Mu��쓕�T�W���$��&�K(
�CF�Φ�VF�ǌ�Sl���>���T�s�܀l]
II q'����6Ȥ\.���EM�)�@.2�*����U�Zf#O��s�S�p�5��fm�g!��Mv=)%ٟ�,YI��=�w��`�|(c�|�mS�U>5�y�΀�T/��4��QY��M'ٿh0�I�(#���?Z6�KN�aȨ?ŶI<�rŬ�0���K�6��X�08�Զ�=#�膌�(���.J��ZƮ�
!Gx��;6��^��U�J5�V�\�<X3{
��^?��a엪��P͍`��a�O���Y�ki̎������Jݳ����.m�6R��+O�
^�H��l��)�-���8f��d���k��#�̫��ʍ{�y�x���Ґ2G8c�7S*�"N#�ͅ%�ܶ�ӝ4��WN=����E�'�6�yUe��]]
�Dh�u�ή��h7�mv�/�2�0��,R�u�\�$�r��1L,`j�%U��"����\���rw��Y�}#�l���UDJo�N�C�\v���TG��*���y�eg��/=��@�\��~r�]57�ڿs��ׅ
�}����'9Uӣ�SI:.�Yp����U���]X\�EIy{�;����Үn��Jæ0���1్"v�Oy�c�D�+����w�f��9i�3�+r�_/Na�i=0���D�z�ai!<��>e)�<���roW�Hx��4������ӹ�#�����P;�����$b�#���!f�>��ݨE�+�f�Ӥ�ć���V�S�� p�歝qСzo�Bo�0k���^��_?A7w�}h& z�N�zԖ2��M�XX�1���ʵ��v����]��ߞ�q����pS��}��/��v{sT)A�]�MdC�K�Ǫ�/M�Л3����c6��m}�;k�:�Z��RU�\����er`Y����c����g�󅩋�k�`��1�_�|��
�$��B��s��)Y,F��6}��4cvҗ�s�SR?�E)��,ҫ��K�[㳛�	��L-�Z,G喯lv�����;[k$�D c��Tm�<��H��G����9�R��t{y�����yt~����R�[LFP���A��Z�b��1���4��U�˷�+���Z2��:�
`�R!�<fg�+��*��0���'ˡ�Hr꾆��C�c��ϻb�Í�WY�m:�3\�k�VK�Y��+(j��(˘eb�����ȏޮ��\��ӝ�]~�3��+�s�!,I(i�z���U�t8� ��5$��h�;|�N&fv�c[f�^%rVEi�!jb��O)���\Bը6�߳����lo���6 �5	�2k���%�;�T>]G�ã���e\g�x�.xg�1}���[$$}j�|�J��I(_���cx�r���n���ʮ��a��O�t���A�g�Xâ&�«lu	�R�hpA�Ը�d��r{˃(b��'���͢H���<�3:�蠟�?zq�����5��6j"v�2�i�5��
V���Kw��!�����`X�i���)-4˃��gZ[�a��@����)9C 4�AW��� K��ݫH��J:��(U��\n_�-EZ��E���.�����ҊL��  ���AΛvQ/��3`���^
]�mܴM_�-��:���l�n�7۶Fvr}�rLy�*5��0��Yd'2��40?�ރ�b�H������]����>i�I%����h��I��G@�1�k��6���!c5��Y����ņ|��x���� >�=�Z����LH��Bh�H]�6������ˣ���(v���l2T,q��`-�}�]d���{3���1&����Ǜ�ˋ������i�ks#��� �<���$���p��U-x�H!��<�g��e���7�A�Ϸ{�k3>O�2'�b$y�iL��H��p6�0'����e�{x��S�l��2zS �� �B�A.�,��%h�]�5mo�����������e��� �����T�0��u�9a3�P�0�|d�"\�7��l���|����x�o���"%]9gM-���N����3�A��o~�]ϗ�@�����R�SHd��ʹ"�a��|��O�[
N\��ۣu�#��N��!a{3k��ZV�[d��(_��0ke�l��,U"N��WCl~��+�����W{��=Ϟ�m�<A��,	9^'�7��R�#�7ȹ� ����+���D�B���R5.�Cڹ�+l�^w��]p����%�[��0ur��矱h7�7v8�SKuNNf�Y�����ڨ�z��h��zCh}��E9|j�1s�~O�S(xY��W�3��^p,�e�iN�Y�Q�:�H��R'A�IU�2e��h�Z���x��.�� 0�^�%������㟪��b��BωN�l��Lp�O�׋��*��7���c.��_rb����ۙ0k�ɾyNe��_��2��>���©�mKSW��,�m�xbX�>=O��˩�����}������H����^�c�p���qsz�^�f��g�����!�$K��L��7P����o�~rr��ϧ�      ~   �  x��U�n#G�w����1����E�V��)^t�<���+A��0�;]]��5�]
�ӚI�B�V����X$�����8M��i?/�ӀÏ�㌅���Q X�!g$�sk,����[��i?-���15�@�0H�֬�%2�u�7��=�]^��%*�y��[5 �F�%��s�Jt<�����I�ݥ���w�z����'۪����Y[���+\բb-bYU�!rr`Kl�Ph��a?��ķ���{�#aB�"�T�����J�9k7t�������QK�-�c�؃��P�soD�����hG*��J��V��g�Ȏk�������~ʎ��b��ҊTAdH�0��@���y^�����PK�1a+~k»e��T��@��)8k!�X��ŋ��yw�>���2�y07�ƭ�CK�9����,��1u�F,	m���[����D�Q����lp-tӭw��p�I�eK8��)�� �`�¯�p1	�����3Y�º(YMݪ��l[�h:���颔��_p=��"3jݜ3tu�-�E2(F�1�n��ЎYKqW�zâ�dEXgX��j�����?+��y�kE��	l�U�X��T��=�wم��g�6��L^�K�+��F�Ee��:�\n��חpŌ1���y]�J��)��ڍFV��9�U��1^=ڤ��P׏]�d+:�K��|;M��ax�?��_rנ0��1H:=�C a���Y�Ւ|�O$���qJd5�xU�u+�x:�w�yy��3�7����[6����2�7�����ܠ�ڒ�\Kam��}���Uue׏5Z	L�V8E}����_$�ftb]5T�4 0�&���s�r�Ӣ�N;�Q�W�������$O\��镀j$�;J!kN�RP��7��|��4Ώ��q�E��            x��Y[sG}�_1�I9�����q��1T��ڪ���a-!��������؊��H�ZI����w./9p^8)�s"#��O�h.l�B;��H�p�(/�:1b��D��9��(�G']{�X����t�-��Ӯ9i�j���]���t���n�ň�������
BU��D҉T#IGtd���3M���de"�*Or�)X)rRfdǑ��M���dڐ�q��Je�S��w��t��v�n��j�<Y.6]3����xل�x՘�YȔ(�2�*9�΄���r��ȧd���0��>���sR�$�ft�o����6����(ŵEF!���ꠈJ�ȵ�q!e��c�8�;�m@��Ċ�%Z˅qZ�~�kg����/�;Z3,���8Z)����X
n3�x�
�XR͙�,������v_3[���M7�lޮ��c�D*���1ՌQU$�*i"S.�Y�5�G�Y"��1�z�!V����q�IR6Y���%��1k_�8Zej�}F:|�6�H�=���9KE'�E�/C��Q�R,-1(�%��J���-���NL���`O��p��u j�0�XG���K�q%:RR�N0��R#o�a4�͢��&A�C�03�k�jt�}�m6��{�k�9��[\�����G"�_�^��K[���`�QHT��ވ�cL�p���t�����[�.�S�v}�FA�N�nu�⮧���O�~dF�LI�a�d��W`W�968'�L.L2����|ݜA6��vּ�X���墝?��{��sR`�d-�;�Q��q�z���=[L!�_�wa&B�w9v4f.���x�P����{
��@�LO	?��MW�l�b�˃��?4o��e�K��}{x��[�o'l��:fWP���� ��c�g�a��~�?���}�.NL�����?^�C�=�_�A�U����`"�d��F)��D��,���^_� �-O��f��8�����3���]{���!��XӔ|���)܋V�E�	��RK�2�g��������(>E��ĉ@�� .<�)����s$�`$���:?�z���/Ϧ��1oE'������
#�0W��` �O��g���su�j�t�t�ެZ�v�0������z l1��;()�o���%	H��mZ9����l���j9�#^U�Qo\z�
�#�~E�sd��	`�2ԥ�I��!�G��'tHS�1��(y"���V��	$IS�Y#���E7o�`������\�/�{���"��&�QDRf0�`2O���A���9:p��G��G��R�B��6�8h�,���J�8g(��}L�-9E�S�h)��G�+edm��`�|X�r	
��B������;�����I0N�y�~��j}���������Շ������H}���������
O�Q�ʼEl�
�%� ޹��6KD$+Σe����~��U��>��ۻ���/��BI<�]��"U.�p�uR`Na{�\�\nww����lC�}v�Г�S�5�_������W,$tG?D'����=|���7�����M�����m�㿾�����9�5EE5��/Ѝ���o�i6�t�k,MP�pG�����<'"W�Jb�e�J��uT�zB�~t�e�������Usl��%��9���T�z��i$�9<Z�jXEiu�pL�Q$]��	�䃸�ב�=����.���al� ��zԷGd�\�	���b	�8�]bQ�)��Qh!�7�zNU1:hB2B�����>��[�����rX�����9���}�]ﮯ�m�S�B�4�!~��جP �3�����@6��}=0ON��A��d��c��kJ�UF��х�w�0�B8&�W���!֘�@"Ot�>n�*�W�YN�>�B݈�Ɯ���"f*���e5�%hB�J����OP`����/�~k��>�����똅�>v �t�	=��AkB�[b0��8�ƪ4��7����6#��K��{^'(:�Qٔb!�8h�xD��� �֨����ͿW��=7m�-�t�����z ���!��"&��T��`~�H~�y4�܄mxxtH���z��}OF!�9��C���Xd�5>a�gҎ&Xp)j�^spu`x�,��-��?����]�� Pl6)Z�H�v ���b1QbN�ч���ԣ����=����ݑ��x
z����nW��w��`Kv7����K,�靛���L9�FJ�}ɕ�qs����N�XK�я"�V��M�6]���K�W��t���q�I�9�8�D������;�=��/&M6Pw.'R�lxԟ"� �i�p%���4-1"%�α��M��]t��	4]	s�(,�����tu��n�7&����
�[�G��7nS按�.T�-Q^�Q��%)��3󝯖��[�6o��Y�B�>�.�o"j@�]���sAW)/�멈�H5��iž���O��n��pB�`s&&����1D[KêծN�IO<|������U�����[x� ��g�g��M<��6<��ef9���o.��|nnR����P����E�x�*H���n��J�y9�
2L=��	u*x?����c9
�����
���^,�O�cr%0��d:0���s�.ޭ�Ԍ�1-��%+���,=s��b��.<<|Ca�X7!��>�υ�ꔬH.P�R?p+����o}��]��J��2q1�C�ư�\�35�
�򢉓%J4�GF�[��(de��.:S!�:����#�:[�����Jk�/̧g��U�|��|��ń�a�EiBH����ƃl�$�sѢTT�G#�0Y+�� ܿ�c<�	'��      �      x��\�v�F��f����i��8'�%;�dY+)��9��_��DiH*?���>�>�V7 �hY��$�ge[&��]��WU����r̕B�8�8g�D5▆ਵD�Ŕ#iEĐ�!�4	i2i��t�J���Ph�0ミ�j5�:�_/g����le�'ۿ�;<SH0E�i)"�K�(RpX��Ɖ5u!��	�3H%Ä��Ƙ�P��?��A\¯��Z}�Rb+�Eޚ���9�,�ވ���T��}c�t7��j��O�[�Nr��3:k�g�p���2z�I	�5�&�}�b��;� i�c�>�_>K����/X��V#�lBI3b5�nJ�$�>2KPV7�4dR4(FF��h���N2��$Mӫ��+uN��E�`�NF��'��$��Ra)v�H��z�\�?���|$�!��z]#i�2ڀ��M�(���f��`����M�+���fZ�A���j:�?i2OSA�I��LS*��N���������'	���;ד��W��󿾘V�VU�.@ӋT]A��R5�V	�����T��JG�/��-�(��3�\-��^�̎���/�\��{>�+��H$K7A7_�ً�gtN|�g�9N�n�����d���[;�K8�\6�j`u2&�(�p�r�d"V4:-�5�#{"��E���j�B��*0�R�#��º����Mf����{g����*]��s��Vξ� O���m�j=v^��ةZ��l}�x�\
�;]T���|G�r��Ԯ�l��]������A}d����e�5.W3x����ǅ�q����Ws�Ū"��_1�i6���euv;���e��> �dq@�E�� �kcvb�w��61O��00�Đ��d�	�T����`A��?B	�z2<y�ۃ��;;����v���^�լ���V��5�duc�q]�A=E���"�I�%B����]�:1ɧ${�x�u-NB��3�;藅Q�E�ݣ���=C���F�,�s�������/G�$��)c%��Z��o���� �4�E\�� �	BDk)��2�1�����RQˑ��|n��d��ɶ�Vl����ev����YV����%@����RB2���@`�K�#���L��@KG#��HS��xthI�X��V��{cx��%�v78�~����ށ�Į���{7{к�_�loT3�u�Xe16�v�x��i>�Ϛ/�Eu�kXf�^��lQ�oo�nW��E�`���r��0��^.�����SN�^��t���FS�N�až�S~�h�8)�6*�5Z��������:g��E&bt A ,�ك����$�4	�e�%L	#y�) ~٤=�<�1�F�W�׹a��������-V�]�㑻�{eo��m��8��_'���Z�mD»\�Աn%ۜl/��Lu��[ރ���l/$ϧ��q���{�e�,2:�M@8!�ih�h��Hy	^P@�mX\�)�����'tA���m�^>Fۅt�����p�F������e-�7�W�'�up��^L����hGح
f��9�|E`mO |	�D�'#	R:���3��>�Si���&-AqȂ�7���#]E<�l�LMc{�ߎ�Gd���o�A ��ټ�����>dww���hn��dWH��c��E��p���y��eu}�G@��l�zo���f$�r� �Gp�p�+ �G!2���ǶM_!��$ QH�4���9�(�B��{p>D議��Ȣ��� �r�Ǵ�a:�����~Z0����ލj����{}�u�K�n�sQՆ�7t�e�>ٳ�����a�zv�����L��?�Ոn��3t��L���dT��C;	~�QD���@flD��X�/J �(D��B<��B�ځ �㞊8�ƃ�C,[�WK�W �i�.�L7��>b��v��IW���|��&j���&j��U��A��{L�C7~ܒ�/Y����uā��8#.�l��]�q��E��J��s�c9�������5��#���zb׳�r0#����A���~@-p�/�4[̚ @L�߶Ħ�Y��k{T~R0�Y�� �3x��A��h�6)x��O`� S�נP�ZI���@����uT����B�I�:��R~���Dh�v�Z�]�h� r�����%�d�=�q1i�yCm��j ��p�"r�S�f<��T6S��0�ɮ8$���	c�)���	'gPx��l��&�{p��z��'"cD��u���p
�g�����D0 y�v@�M��]gF@�C�6��ʫ��&;�a�	3��x���F�g��p�C���֒mώ;f�7=Ƞ�5VzV�5�����Qn��Xa��E���.}c�`�7 ����N2��������B����]I���f{5��OȎ��e&�q
��}3$]�q�V�!��N)�k\u
G��xv� }!��V{!$ւ�> ��{��"���4W�Sy7)��9IaF*����6��RiI�)�`s\�P�\P`P|g��@PL���Y��g�&�g�v��v�.fv��"����ݏNc,o�X@W'~gG��;-�f��j۞7�ww3�*��]�65�ږ�TO7�����6�d�y�n��T���>Q�V"V�
6G�vT� �^��d�$ȴ ��G9���-�5\܂����`\�����3]| s�8n���C7�������O9���s�06�)����O.YN �.��R�R�lf�ujWʀˁ�����$th�(�m��p���׃��^����;��1<xms��n�ЍWS;[�/�I$:�q>�0 ��%ِ���q�$�9;�RC�%�=K`�Ҁ���OSH�#�=R��]���esÏ�eU'C�O�^؉��<�1�C��D�����@�d5��6X��g�I d3����1�n�0�.���dV8��-?W�6�0}���0���s� �	H��:?}�2D�S"zeQe-!g]�E��ZiH]�U婷V@ c@"O�j �	Lz��tgj2�˩!�Ju��('���L� %�y�C�@{_ȉ��1sC��9�ء���vɭ��<CcUC����.J�Y'.�f���9�"f��#�/~K8]��{�a���uՄG��O�\퐖���]?FZl���������ɺS�r�R^�kNJ(b4�h)�������R��CcM06�Ej��/��Z����1�jƇH�Y~y:��`���f��mK���>߹� [�y� �}� �a�]a�z�h����i���v����$%�C�Q	ɈTY��R��H���4Q���X�!���V��l�7�X��"�̊�C \&3~��`��H�:=|{x6>:�N��Ó7G��L���q|>>������ϫ�8z��:��OJ�����|���G�(m��/ޕ���P�a>~3�^B���ɛ�h|�����2�]�FG��`T����|t4��׾k���牏���� �?����wgoG������b|=����|�+�V·o_�?��F�g���Cx��^�������)\SO�`�hFo_���hӶ�= ���S8r__����'o
�_������� �z|2>��|���;>,ߺY<䒀�Y��~jol��f���Ę�T�(8'Oy��3����r�tb���"���2�
��E�e���{�a,#�vp�	��Hg���-E���SQ�c����9V+����.��~h�,D���T;�i�e�&��g^��Z�ǟ��~
�����G����(t��dAcb�G�B�^V��%
Y��F�D�.:���:� . O0A*hIV�8��Γ���%���A9:�v�#Iޒ$�J$9>w�;ݜ;:<�iԤڽa�����&�@��b_/��l>^,ktz<>����Xߝ��Hk};~u������?{{U�2��f�9�{{��||��^uqxt2>��'Gg�����q�{�]]ճP[Z��i�1��3��q���^~���iU �Vj��TM!&W<*&��l��1�@%c�᜚~֒"d���_��('������9��9�V�d�3y����9c�/���0K��A�t^ �	  �VGIC�͂���00���G���H�D �2g<��ȳ(tД"d�a�+7�@lt-?�����ّ������J@�g�����"k���7i˄�������#�\~�.��!cf�C�	A��Q��:T�	�_�c�Dʤ�9�N#GBB���P���Q>dtH� ��M��?D����?Bf�$�y�1�l��3�@�i7V�(�ED0H��n�P$�s*/@��v*��,!A>{��5��� ���o{Pz~x���`��r] ���(���>p~_uA;�����p�Q��-�DI��d�e�d��8}������y�s�j���xr�(�^�����w�<>�A�N~����?G�ض��C�}`��?���R��(���ZX䔕(�H0�$o�f/O�;�H�7B������T�,
�c *���]C��հ���-4�u�	�-l�>��ի��y����rq7�N��V1����rѫdݜzb����r��,g���h�+Z��+Z�T�z.Q��wv1d8�Bc#��
7�� �ZQ䌀�OR����`B��!���7ȉ�f��ԣ�����\z�4����j.�?��_��b�H�T��{W?� ��� Q�%!�uᜊ�Q��1�eh4���[����<x�ԝbHO¤]�a ���P����۵˾��E�T<,̹�r��dc��Jj-t��س�Zi�%���.
�|/�)s��JDx��A�EZ�Xb���N�!�F����5
�������H�2�$�`m��ڳ^\��v2+���!ߴ�j���*�^=��xϣ�1�����q;�5��y��Dh�+�<�S
My)^TOvy!�����-����ڭ�ի��u-o�5�xC�_l���[*g��j�T�;v�Yg�~A��'��S�ds�V���T��~����QǗT�rǘ��F 7wp���\��QA�-�`cH�u��UЀ,�Ii!��J%&{Z�x[��J�PHM��� ���8���+f�j�"-��KՐ��J{Y� �ȳ�t(8OX2�b�*�`-�V!�Cv���:��JF�u�wZt�A�4N�Ȝě���W�t��]���#X<_����:-_����r�}t��C�lݲ&���C���C��n��~���9Ó����@���[�I�������݂�:����ז��`��Q���Yun��7��w��TG*v��1�B	,Hb����)�Q�dr�gTB� ��;��Q���Z�y{C��&���xd��{`���뎋2� YUH�����'AS-��I7��7����CcSd����{�:�����=`�U�4����yvԀ�~���5��j� �5�|�:�a�r�����>Y��<9�}���̂&��c^$���B���T�B�P�Bo������㢔zGl�n���(���9	��)A,�WNF�&����Ai^(u����e)a���ɵx�&��3��e���~ASo��4����U��nxN��rmg��>ڮP�4�ݠ�=��1t����C;�vl�җ�0��lr�DQB&�W�A�3aH� v��6GKY����t3���O���8���!��+~	'#��Cj�{�rS��{��;-P.�y徠�Es�O���˟�^�L��/C/u�����xʳ'��[�!����s_��3)���������Kf!էLHʃ��{�ֲ�Ǡ����A,ʳH�k�`\"���QŌ��b�y�!��md�`�٣�Tx�+��.p��M���T�AT� �yB���|z�.�#�\ȅ��ǿf�?�/�_�d"�*�od�e �`2��J �io��j�cf}PJ o%����=H�ƈ%��ɾ��K��*����;s۵�g�����ݕ�I/��Q��5��ڧ�� Vghk���w+��u�yl��Y*/�>xLp�Y���BO˻/��D�]�*��;�x;)��َ���i�6����ΰ������GA���G	�xQ���_�_;�	ěRZi�����yǣVI%d�"�B�^!w��y�;b�w	��ܜ�I{���C�j}�xh0��-r%���|���/�v�N���t6n0�C�=6���M�͛�O���_�Դn7tg;�l�T�[��W��B8������������ ��uʢ��~�by��(��ޠ�`��:����%��������@�m0Rp��#0HSH�H�^� @H~�`�^*��i��/� آ���h���p�(J����1��c�=	mӽ ����#����������?]L��b� �76��Y� �8�-FR����d5��i%Yb�+�l���3TD����8ȁL���Bme"<�Q�K�GSv���>e>C�E��_�o�"W����mE�V�b�{�ݗ����:B�:!bS�ۖ5��t�_��� ��I樒�u�ǔ/�7&�#�MyC���*�B.��5�$��p���7�|�CK�      �      x��}[W�ȶ��z:�{4E�~�8{���p�Wz�R�;���V�_fI�H�����R�RI�-��9g͋��K(b8*ę���M���1&�_�`����;�	��2�ĺ�z����R��PQ!��c��2�1D��,1����Cs6�9}�{���ǖgR+�9Ҕ2�7�	���I%b���f�j ��Cs>����[�?<�h�;"�L0�9K�������$�`ňahֈ	`�A�` ���`A𐩡 ���x�,��,�IyZ�����xpT��_�������bR�zU�FųB�kj!�&�;��^]~��$�~ye�#��^C˂1ȓ�=z��Q�^��*�9�l��ӧ?o�Ϟ]�|��^�\���}��s�v�����O��Ȏ�`�����͎���Y�p���ǫ�x�O{s��:�	C6\���㳤�`�G�s�s�Al����B�λx�W�_'��=��"�dq@�E���,���q��bb�ޒA*
c�Y#V��0�4^P��_3CJ����h4�+���~+_���������	p�����t��y	����x3>� �)��C%Sf���*��b������У�#��dz�������I�#-r� ����t�3A9Kx���?_�9�D攄�oR�J�55H��LAc�hVm"�&2�9'2-*"��Dd)���^G�P����dr�β4L6>����pZM`�W�g��{hc��L��X�d������ޟo���]V�D��ϭ��雞Ë��r�&����܋�����)��?�?]��ٷ1�C��O���B�-'�bW�m��W{l�6A
2�#v�y�RDI3��@j&yDx��Yɕ;v��sl9!��I
O�R&��1���ِ(�b)l2V0P��D_[���3c)sޘe�e)���(s���@ʼ=FםI7:����5�>�n�6�;z�DK萑���iPyS@!z��5Y��y�
��d-�y�2�G�G�X��p���5U�>��X��� � R����}�jDL�Uͩ���h)#�7mĬ"Z
��Rp�	�!H��v@���O�Fc�}�FŤ8n=ٛ��ϏFl�p���Y	$^�(�J�+�~�Ⱥ%Ů;���o�[���ws��d������[G��s,4���TY闸oa�v��@���f�#����:K��  XbR��a�!�2/��T�0��� Yc=p��֤�I��
�g$"F�Y�&�#.���K+���@�<K�+?4k�XU���ϒ��c6�+ʣ2�N�����谼����p��/_�����QAA��!��a43Db.6X��e�ȼc�.�2S�ė�琙��{���6�r=Ħ+���(�,�́HIH�<J�@�S:Z/\����b�-�� r������=�$������oia<�R�$YJ0]��cy�e����Ɉ)�����RQ��[�H� �K�gǓ4�$Bf�?Q;��,,	*$G�F�� ��@��)4[�Ȑ�!\1)߾���˼&S�>������YSf:������hΑE�6���� ra-W�#��A���=HN���@zr�z!8����_m�o������O�m�@%���j�M�uz��ƻpo.���?������T;%��u����@C���|������Sdڀ�Ah��<�=/��g>�Z��So��m/v������\�&����q�x`�Z����ሕH�e�!����:��0)X"E�-�R2$lpV��N�N�@�Xe�)���W m<�;-'�?�R��lc�Qv�5�0����Xƿ/���O���˫�����.^v���G�77O�)~H��2Lg��n�"R�m����Iz���_����.]:4H2�IĔ��G�2�Pd�f����ﳀcmO�ϹH<�D���)�lbQy�j8�3�v��k4k�g8��9�RY��T���Qq2)O���o��e獳Z��)��g�Φf*�!?�έ���U�s�L�k��~Z�_�7�oh�O�[]��X�F�\>g������hѥ7�,$q����k)�q��Q�So�0���B�1"'���]pkep��U��8�����r.�@:Q��J)[�)K���L߭_4TX��B�?0�c8QD�(�f�.O���,iB3�pˣ�Q1�1�q�FB�4ƴ�Pqh�b�`R��O�ݽ�r|\�MF�iy�����r���?;��ur<�=>(�OF���|�r�%��cZ���hA�LH58��V���s}Y��U�ů�����_����+4Q	ESjR�������;>���hڿqv�]���" %EIM�IC��&"ɥ	)b�	��R�y�x�	�}�V"m�9�;����/�
�]8�2�1H�AރoN;)��W:�U=Smg��Ŧ��ߣG���ID��#�N���`�C!
�Y%�Y=���Ey�65m���M�"� ��;�������;�ү��_Z������m�����ͥ�F���Y���s��'�����R�d�U���v`��h�T���s�"��F9ho�f�w�et��h-�Z�[>D��������xhjJ�\e������S��P���IDFI�U,(�%ôS���0�!'5(J��h^���&	���^�l��^D����f>!�mS,
���;�l/�,2uצb� �y���a��˂V���^�j\�N��pyssy�����E/[u�G�����GF[��4gA�AU�F҄1�����WȊ�J��4Xj*1G  Z�}�����&�8�&��ý<�q�K��:CEZ�e �)�k����}D���Wy(	(���^�1B�Q99����h|6*`����m���5�Ü]�8��*����V\f4�ⵀ��+�2�%��K�5��z����]Z�V��f�ޙ�����Ǹ��o��D<�ЬI�h�N'�-p�O]�l4��rj����K��\ �qgI
�ys� �Dx�s�$@^�ns�QD���DB��s�4���R�I�"�o�+S�x�t���.v�ρ��UE�#�ثO�KY�����;in�i�i�o�V����Qx�1�ڟvA��C-����|��ٓxe?8���꽐o�]=��⻿����ZMʻb�YZ���b�%g�����r�Ӗ���c�L����T��\��q�$�cHP�wi�&d^�0�K����s����24/�:��L>��&�
�m;-�Tn�}֘S{�"�:0��!�=����m����6�S9�]���b�ȃ0�J��Ҳ2{m��Iv��̩
Ζ�r�Q�L�-��L)a+���Г$�:J�d�Y2�w2Vp��d�D�`�h-�33�f��	cӴLD��ɐ�l�::�l73�����sd_��ɯ;�]u.�\؇b1xis2���k[�xg/�?_]�.�Uy�5������4�h�py3xq��_W�@ޙ_��������?�ŋ��S�@K]�����wR���ǣ���V�����&ϲ<�Aw����S"ze�(A\f6Qt�Q��ER��l�ː����U�`+��4�/X ���o���ֻ5��݌����_^=��� �~���*�����|�چ�i(\��9��Ds�s!;��,֑1��2g��H��v�՝f�#4%�C�IPÝ�i�Q��2�I�U���k`Ԧ��H��A�K9f�>a���S����n2��s��T��X��ic?���}���|����O���>��~*���O�?�4�+�n@W4K��\'���_��L!Ir%HoYиC�Z)&lZ��A&E��	��q�#u@��>��
�Ht��D"g<0�@�cs�N�C��z����V���4��b<8-�'���|�j-&��ޮD�-�W���|�T K/� =�.,;�m����֤���t��e�q����8���:n�'���ۓ��BCy_��+&O��-Жw)�J�鈋�c&F�4�Rd|��!E�$H�~go�b���!��T���A���"�3��BAGK�M�0#Qi�R�¹�1�k�H�fhv�6�)�_�E9^�    �;y������y��^�2��$DD��9�}�l(?���yMDs#d�]M��̌;�z7+�N��?*���ˢKW؀�f�܋�Ŭ�g�Xwdv`��`������*=�h�"��ݩ��ٚ+�FZf?~�ӼK�Q0R���z1�NsB�i���	tֈ9���?�
`�g9�^�~�O�U^��#��b���X��l�4�k���q1(���JK�Ι(�+�tVnwm��[I�=:Ö�0�T�(8'O�i���9�-'I�i(2�'B������3�Ъ�ɩ���\U�P^�Ť|Y���×��h�Rcf��ʌs0)�ʳ����Y	�-�_��ߜT��f��D��)�1����w��bry������K�O���7��yv:8�N�;�+������f��Usc�_�|�U*s�ЎRLO���lu��!�9E8I�0qA��j%���dB.Ӛ�����I**����Bcb�G�RU�7Z�� IX�	o;�pN��l����أ�*�C������mHM<<��+meAA[�9��׸mBb���[���+��Z?��������A
���A��ٜ��8�l�9g�:J��-���i�vl�"7�$��Оl�}�9r��`�x�mq2=/wG�kŋ�����Be�u]��=/��èĊ��jZ5筍ͦ���2���L�~7�.�����ϓ??$V�$�}W�ݬ��i/����=3=6n1ӚZyfr�R�"�{`&ő�� �M�8����,���(L�M�kc(�5�đ6������s�C��#���wG���ʅJM ������;:)Ai=9e��zo�c�hONo���=������ھ+�?.���w�����Ss����X�1�w[���EPB����bă���
�b�I���SJ�@O�\B�Y#�N�\b!�`�?SY�z]���	0EU$����������������W@,�?**�ZW!�{��G���{;7�j�ek����c,��ʕ��:w���tH�)�)����-��I��6���\�]��%�=��$V���FW:��y�Z��u��ANK���*���r��c�:�SY��	�-��X�>���aG�f�j s]�!5�5�:_�H�$@�U�׬���y0��e�����a19�]�p��S��_�g�����D*_��YA��53|�̠�
�E��^]�������tO�#Govы\m��U�7?�����G�Ul�&_8xS�i���鋊�0k�]����l��������-����O�{���7;��̬�]�A�<�g����3L�T�L�E�ދ�2*���#(.�I������.:	��#��9�͹��HI�Jֳpo�.P����U�G�a�SV��"��/y�ZU���{���FZ{+q�H�
��c�f���h�����\5�ˁg�e��7)��r9e��*��'�_슂l7Ho���{|1�vY�q�
���"F���r��`�O���%ӮK�#�YtA)�E�7 @/J���M�m�'�%=��Ŝ�!���0&DE�:���ms���b倲�9��%�2��!c9]���[��W��ɨZE��n�G�)��q�_����6�@����S_\Ze��83W.}|J�e0��^���Q6��|m=~��z>����@6ۚiut��M=6Dی.�Pt���� ��������<"Lʀ�q>�.�Ws�i�9A��6�9 b�s2��^��Z�dr5Q.}�	��5	m\�AH��弑�fV̬JQër92���)jzl���7��y��/���m�-.YB3��HWɻ�JT����8
ik5�^;.C���?���S#���b���9H�#��^�H�����w�����c�$L	9�b a�F�Qvʒ!�@h-���aM��q���fI���e����E/�~�h	��vza�Q�f����m��a�M���sd�wd-ρ�D��
��#=��T��}J"�$GEG����#\�XNN�2@��"a=�2�Ԉ)��2K>��``�Y4V����n��b68����e��V���6�/�E�����UA�,˲�9��d��xr��dT�$�@���?����Ȣ{�b�C�r9y���W��g���o�W�����r����t���}�c�h?��&�>/��K(�m6����*�I���R��4K�]Y��Q΂LK�T9G#CF�J�4v�'Ab�+u[�WӐ
�AJx�\�Zj�Q�׉���ĐK�Y�Jk�d|��h��T%>��S�h��J��޾УG�؊Qx��A!��B2d�͕K*9}=��l ��J)��hֈ�̂�H5°��XL�g�*1��QY����Ҭ߶D�+�7ޝ�F}:گ�l�����j�������UQ��.�U���U�W��ܗjC��w�J��|���rX��k����v_��m^�1�~m"�EW�����ʝ��~.���}W�^���Nq���\�^����|���~m=���&�:���f�e�W�Y��R�\`���!�G�Lt(�<��;���W?fRY�DF缲у(��&<'�FP���'���\�q�����I��.�	��/���Ѓ�"Y�oϋ��d��-y�vm��ptT��,K�De^�Q
S�3��O9�~b�}�����}�+um޶;F[��g�� �w�g�釺����;�j�ݾ�m��^Ǜ˫�f4�D%w57?��SF����5�l���㋱���Nqv���h��/�T����a$q�a��w��������6LF����܆�+�p8�߅��Ň?�6��м!�5R�zp�S����D�:�d�z~y�y���"���ٻ�A�1Z��x���c��<�L688�Ưf�#����<��Mo��ۃ٧�zn�n�V󖥍��;}��Z9�eg;Z9$��H%
$��"�TDVKŃ",Xۥ�BJB\�bX�ã[4��1jI�9��!i4/��8�-<w�'�Ʌ�GN+�S^Y6s4��P�zU�	\9����Y[,r���ј��I(����=��nY��$^�G;�7�?0����pZ�qq}q�1}��ȱ�&�8!�Q�v�1�x�f��e�哏�'7�)�26_}�*��J���p�'�a��[Ҭ�����E�j���2�<��5G������:Nh+G�a��}�0D���9�"��vC*	)T�zAӠ�������CX�Yg=�Fͨ��_3#��v,�� �Y�H�*L���9�Tl΀�3�k�Z4VQ�� ���Ȏ;�RO'��G�Y��������.��hp
�G�����W�U�3ũ��i�E� LU��Ÿ��pW��<د u����٭K�K�/�j�b����|��XՇǳͺ� �?���!x��\�@,��<���in�&'���Z�ꨴ�7 ������ɂ���!͙#��%�{K��Y� ��`MED��r�uL!{N�9��)V3��f�T�Ae�Gf���gV�D@�}{^�S?���[�ם����br_�x�q�\甐0��G�U]��I�3s�ms�цuf�Y�:]���>_O�������1�7�M|��*�Y'�-��'c}��m�� l�\\tiX�go45��c�lhz������2��\,Y^Z����J���}�ّŨ~�H�dz��l�G����a@bwYr�v�UeRwh.�J����	 ���!�1���jk��nj.Z<�I3Y�	�����s�r�-�\�f-K"ѭ��L�N��P�HY��d���(k�,�9,����r2�;,������`S����뤥��	��8gr�f��EV.(5�`�dG����觩݀�|��K���Ez<!��XqX�?�_G~[3��*t��;��CT ���r�i��QAy0B"�q@FR�9�Dl(�$fV2��c�1��ԡ@)!VhB����r-g͙�W]{���\V��a��"N�EZ�Xb��h+�"�l��m��Q�۹�H�z�� ��r�=���xS�t#��hn���պ[�K�OY�PS��-[*�f�ldڰB�,��V�tu�x����7=�/[������q��ݲ>������?@|�	>����<_�4=�������/�0���x� �  >�T&���خ*��-4Ny�m�鯲�k�+�&��M��E�2]��E˶Bq�(:�-V�11��I,'�_���%O�d
6�U�N���q�k�pǇ)��פْ;~^�P��u`�f����
G����\.Y0)ߖEY�<�ժ%L�9ߞ�r��?Ǉ�eL�X���TX�V��[�����g�z����XƼ����أcs��}`�"� 
$~��^�mW�z�q���dm؞���=��$OO{M��\g�3����L�(��&�@H�"�Uܺ�֖R�w��ik�5n�����x)�>�Fo��QĘw�K�r�v��S^S��׶eQQS��v�lMVdΦ��ʼ�����Ԛ����"[vun%:��Z���W�H۹C���H�j=-^NZ�Y�ڝ?Y������y�:�]<��[<l1v�����:�b������+o�G	\�dX-Fw՗X�R
d=7�Hq�,�Y�6�x�E�s���
��v�8�1�X'�&J&��_�����C=F�����I�dL%E��}gk&S=�۞6�"l�f=Q0���m�����ě�'ח._,?�)b�Ǖ��f�n|f�o�y�4{g����&���t6D�z�J�w��X�Q;	:D4T�&N#�d��bd��i�p����欑���튚�e,r1�Ｂ��x����"7S�X���q����դ����1O��^w[wz�o�\3�6���V����t��������R4����e�:w�}�0M9�p�{��	�TP$O�{���(�2��E�+�f����E�#��%5��lD9�/_�E�;:<�f����;���0��nyT����l���r�'�pm�����8Vߓy�E��p_���w^e���~6��/a^���O�
�r`X�rT�h�3�
�as)��iBX�II������k��EF��x��%�V'P��T�����J{��q�9�s�A�y�C-�m)�L��8�d.��7^-������<�*J��x�8=���J�}u>9�����W�qq��������\F*�d��p�N����-�1�����"�Q��@����'�#a��JOU�@�֒s���K�s��CL�0����)��0�`\�!�?�b*�6P[ٻ�(����=�{�x<�msB����$I*I�2R�	��Y�9�UI�2����~�m���)W�+����&�����V�C�e��{ڈ�X��ͫz  ���cm�*��rP�y�µ�.ʝ�B�����uWչ�Z�m�	��պ���}M����ܛU�^]�������}E�6�:;1݅QS�SsbX�0�
9&>'.2��`��;�{�])��j�0s��@3�D�v[)��0B��@�)�����)sLA�	&�434VgYK��%��OB�?:��L	K���K>1d��HDet�R�ڥ=�ډ�+d�=z<[�'M�(j	��Y.r6�HCT��i,��z�b�����=z|;l�H�
&��stbv�Y\	n���ȹٖV"47�i#�r���fK6CΆS�_~��~���_F�`U�v�*�|��νN7=�T�R3���[>U�ͣ�'��? �u����I}�Z���c�(��yēHGgP�:1'}
������T��LѣǷ�V�J� r�e�v2�����4^{M���y%+0�(�<k�J-r�\2�82œr�ѣ��`�2�Xs��'��Ir���Þ;&�3^ͨ��7�k�������a+p�-N����t�9�'C)	�9	�E�.b�7Z��-�=zt�-�8d@�ϥlh�"����hO=k/ى��@/�_�ݣG����̴Zrd�M�s�V�!�g���n��ؚHƋ���=:�V�e��, 22�iD�̥�,��4�B�ͼ�z�G�αŅr8���\�0�A:6�@��6`��,/�g��po��ѣ{l1e�4X#�F��-I,��s�A��R�*[�X��G��[;�A\Y����'碳��M���0��ؑ���}&�=:��7�H��b�#��1�s�j�5U\�v�L�h�bB����ĆV.&^�U&S� i��d�ܤ�����x�_�&����Y�'��7�Q���B��j�]_G���6�˛�}��,�2�l�i.8�}_(��
ڸ�����2n���H��A�`12:��HW-�#>Y�TЈs�E���#�PFs���ݼ��9�j$���~9�"	+�	�2��4��[;[[[�]=t�      �   T   x����	� г�%%�FW�PJ�^���#�B�(�;=ih:<�M�m�77����3fO�RN�b0����2Q�}�,Du#�\�      �      x������ � �      �   �  x����j1���O����HZ�K�ĐlZ{/{3��:�Xh7x��Qq[j��4�ƢW�����(pI��sq��kf�=��yb$��s�2�I�f��q�[�|�����
�	]n�W���/2�6��v�_n�}rl�4�k�ij����Jv��>˔S%��� �@�	�l������W��B��J�������T&B`N�=��.R�;5뗚�����&�Y�~�e��`�O@�-dW,gP�m�:��QP�@����dC���m�;�}YQ:��H�tYĎ4��-t5jӜ�2W;��a.���m���z�5*k��GV\�)֚��+M��$vy��H�V׏J������:麺k�0e�����*����^K���B�K�Jg(��;��b�Z=8��      �   �   x�]�1�0��9=E/`�8N�t�t�b7�����"&�z���M�����Q<��7��&�\�`�@G�$j���ZkXr��� ���7���e~��[��/�ꄣ?H���7����~��-A�V�;�j
s����7��a>�O0      �   ~   x��A
Aϛ�D2I6f���{��L�����uih����xG=�`i8�+�`���~Y�0��Un�v�J++���3��i �I�8Z�xH��]}�TI�����~N*{����� �Y���      �   �   x�}P�n�@<;_�p��fC�$8���-M��Y HUU1c�a�ɶ��
N��д(����B���#����h�ݠ6�r��x�7�e^󒗴�5��y���o�\�./<���d�����%K=A��~��x{�>/Wo����Ձ�͟S�@1�SP"d��~���-�i��t�5݌M�� V�h�      �   	  x��[s�6ǟ�O��d*ȸ���I#'V<�݌w�����:�L&�����d������{�?� 
�H�.��4�6��(,5B�<)��+\��-ȉϫ�#��MG��/n��"Ņ`B2�"��(��%��NM���OO�Y��pRX}�O���iȵ�XBB��t�:Ӊ�Ṇ��e�K�v�;����i���"!����6yA���K�����F�Xk��Iu�bq�&W�q�H��É#_�?��pC-2��������΢���M��uu]��M�d]�!����C�tnE���!Jt���P[m��l� +7\O!�UHm�I@�����kHw���!�o2�s8���a�nʱ�� �������\�Q�vt���/�65�;�[��a� �P��[T�I0�4��6OGQnn��SDAA����~��֪�f�&��Tq�S�����(g�v<���*X���g�j�12ޘ��r{_�荈�u#bL)�@&u-b(�p�N�h�l���0����N�)\��}1UGg b��e�r@z�1���|��2c��ݛ=X�^�	O\�;~�*y�X�����D�d��n�ɫ8�k�v��xK�_"A;�<�9�r+��>!� / 
�[��W�ٔd�!_��A��'�����O�$sc�硧�ǵoIݒI�(��i�N����O����s�פN�& ����a,�[T���<��l�rc���1i���d�WзC4�%\	�nz���ۍ��f$�EVu�8�j\�*�v�Ս�T��Zpn1��`3(8��B��l�_�f��]w@���p�|����������|g��h='�y5uU8F��p'k7&�_�)�)K�-�*���
��z�گ�vxT"b���1��D��wg��|/��9���Pxmװf�M����Hn6��-��W���s|�X���l������m7���z5�n����&�߳���l�ɱ�,�w�mu\�V���jY���f7>�e���,)��`�'FP�dF��F��:)M�ݛ�o�_	ȁl��H�w@Y�ԝ��d4�����u���:8VI�����*D��L�RO3� M �� �4�J�X/	�.; ��|ɓ�>��t@ަ��.饽��|�t��O��׊ځE�@�A�GҠ�$7�
e�ݪ�K~��E�Z/�ӭ�
^.?����vSe�k�B���T���������M�W-�c��­?�j���u���g�F�Ͷ���u?{�)�Gn:�o'(�'7���M���z߅�����=�sמ��xH�����x�J�u5�o&�]4�܏k8�.��z�9,��lH���wqxՈ��)��;u?�����#/�vx�} ����S"v���S.�I�
jx�m��9��G�h3��G+{���\�B�	=�;�?�Bx�� ��va{s'�N�4Jt;�߈��m?D�����Nl��h��{�z���w� k�Χ�LY0��T����Z�2j�$NJ��������',�+Y�LӢ��*�=5�i��5��z�"�<�Bʄ�1]P%dFm�-��\hn���|�"���e\p*��R��X?+5u�I�#Փ�B�dNko�Ȝ��sC�z��Jg��A��T�.����5�4����R$F��.�SI¤�2�j�jj!c�g"g��26�.��M!�I5:6
��!߄��[������Dئ!>�W� ;eά�Y�͝�o�<��dN�N�'Zg��n����zM� �j9�z����37�[�p��2�v���z��e��^cfj������e������9�W��Szv��{B�g��f���gj���E�#�i�4��N��n��ITXr��8�o'}��i�c���b��K�6�R����#><xq��r�wp��3h��h��b�G׎]���3v�ճ��AA�;١�͒8/i�%�Z�����������P���E`[���D�{=� � ��m9b�&��yiUL�a%��ܳ�g��3^��{c�͵�J��f�=��z� � ���(.E\�&��`<LIc`%��"�+������%\n�i�_\����`���E��2�3�<4*��|o�� �?�ݤ�,W�eF��vT^��qV�*s6I|݅���M
�3ͥ�I!� � ���I�9��T©JbK�V9�˾�"J�ۓB��d�]�ipR� � �r8r.�bfeY�q)55��̔J�4��oY��l7V�E�%� � �r8ʊ"�eQ��fB7uq�1�2�u�-����pl�+Y�͌�X=Q�AA��s��}tt�acơ      �      x������ � �      �   S   x���;�  Йޥ���rc�Y��Gpwv$y�+��qG��xP�9��9�G�ƞ�}?)�X��$�cY~���XH�3P7 xt��G      �      x�����F�&�;��[6vI�� |Ò3�ǒ"%�(R�$kQY��9 G&[v,��~�;���5O0�0�&�$s��p �����Z���@ _�~��y,x���%�h��\�<�a�tIGd����,%��/�S��Jͫ��[=�QS�l7����#�m�$,�T,��^Ty0�+�Y����z��Y�={�Zoo�j]e�|�7�5���^n7�Z�7�N�\�}�P��'�r�L�W�V�����U����LxO�eAD��$S"!2��\&e,��,�F�������������C�ʠ�<�lt�Y-�Wj��bu5	�g����V]�?�L`.&��l�N^L�O^?�P352�Q� ff�fC�>V������0��F/����zU��	��<S+�8Ltp��_UWU����;���Z/�L��͟�~��F_�o�U����}�\-
X��j�N�_�_||9���˷�u���i+�Uj�./�����9Oh�b����0�������[�n����C|ǻ��&��Y.�����������?�^<;:��U��.����l���oL]Up�=��Ъ
ԍ��ǁ2���l�j�F�4<k^C���0_��������g���O��z}�x�"8^�f.�����>����0����K��f�
9�p���|]�v��7���Ç��t���Ɍ�a�r�EɈH9%i1RR&r��i�Xg�d��b���I�W�h��N�G�?�!����m�f�ިR��L��z=qý{tf\�S�Td	I��@V��$Q���PƑʩN�S&ឍ��12��cL�0�ì$�
���:#����H(�u�B�c,��];F���Q��E%Ӥ�M�2m�2y&�Xt�ȩ�oo'� �l1	~���?���,�)�<�!��d��$/�,dQ���;��n�w�V�;����T>�x�C^D�L�e1Q2eDS!i�i��0��a���Jq��
^\7x�q��f9�J)VH�I�����e�Ǌ�Bf�2;�4d)~�c����Z̀����$�a��h��ئA6ˀ�o�su��s��<�I��yX�$ӡ&aV�� �&�|��W}.�#̲Xd�,X+`��^ׅ=�]��5(@�B�^��]bl����@�s��v��u�8$0���#K̠UsCQM���U�i�0=N�[��p 
��чj�A`�7�����Y@�s����5�5p�{�^��۹ހ�"Ge~[_.~��g�.������+�����r�-�6�c�=$S�;���e^�M�\��f8�fa��W��竝�o��IV׷�@n�)jlD�l�(��54T�Nqп�x{����QOJ��f3`KQFDq�2E
��9�ȩ��ӿ@�F��udU���]��߬4�1L�����H�������[�:������DüN�S<n����uۂ�=]n�R19��.A]1� J�"B�$",UT�� �4�J\;mϡ/���D\W�S��
�H���n�]��'���x/�R�����j�r����]M�;���A���۱'}�8���f��<ƫȨ��N��(�`��
���sت�ay��_) ��
���o��>��KI�L'�(�'��ȜEA� ���T�B�[=@�1����$��C�?�2U&#�Ӵ BÏL�		E���<J#gۑN��X_^��;�|�hKGdǼ���ד�i�i��$/�����#�IJ)#�yXGR��%�E�r
��ρ�T��=�M����'s�g�#~�H�Tӄs8q�hZlW[<���y��}������zS7`_�D�5�p�?�զ�~`�1�q���,�����'�8һGj�и7HK}Z���h~T@}�բĖV�X�z���?�K�ʎ�
;����H#Yu���H>�j�+���|���cO��E?�p�=Go���Ǌ7�9�L�4�5=�S�(�a����Y� ���g& -�kg�Z������v����VSK�opW���~��O�z]� a��ynZ1*#�Ue[��b�����|;]V��4M����ʹ�=���\-r=�-���6�maH��j��0� �U�jaLaᱳ����|�����|� j��B�ճ˅�R��r��Ɲs3�1a`�}�e�{��s��
����.�oVP�k�vȳ�9>W���rdl�n�f�9m����i�M��~��J�ݬL��V��&8݁�u�����3ã�l���Y Ր�v5���NmoU��}ki���-%RKTi`Q���n3u]�����Y-�zݶ��G�\x^��tԼ���1�q�f��0���i�y�M+X�����)e��H.��?A�)�L�S�n������p7�JI�n��E7
�hk`!�7�^��GK���j��^���Yt���m���G�mUX�^�nj9Β��Z�,��7�	��|k�Ƈ0�՗ye.;eI�bMc"˴$"aI)K�%G�D��o��I4r2"L�'Cq������ʌ�����ߙ��Xd��y��X��((�e {�)W*ʝ��F�n��=F����߯�l�]W�~���w���ѿï��z�ӿ=�ox}���ſ��}in�o�FOg'���Ϟ�\$��'�e��d�<!e�@/��Hâcl��8:��q`�'��f��%���i�UZ$$�U��E�I\��s+.:zM��j�z��'�g��7B�I�!D�8I,
F�@7�T�d����X�8����1���i	@�o�X����3K%A4�M
gw���/�}��K��/(���lV�,ص.�[6ȤQ�mM��~�/@w�Gh����ZuY��p��P��Z�~���]�y��N������V��~ U�m��w������^ܠ��q]w�@S�n���b����d}��1�i��� n߀���oFf�6�)��.�Ǽ��S(N;۹�P���x�g�N}dA<2:��+�2���m����xP�@�p��4	��V����g��j;�lW��B�;�˅.��^�[�aznZyz��0'�p{�V��,Z�����Q�M�{V[c��,w=7AgS�'��9_6���������V��,��ogS����.?�ճ-l�U���v���Ƕ�`�����o:w��}3H�@*[@�P1l�v���b`�,(��Ӫ��U0�+�w�q4�j^.�����u���F]�x�����|2a<�YF�T��dU�Hb\�ҬJu�|	GQ�'k
��x��g����)��pn�Ғ�4#�,s���$�B�BS��	�W�s����?}�8V4>���,O-j3g�Zoo��X���Z�(��
FýY�7�<�_�&J돔|Ӱ��c	�}�d�����Gh�:��ww�V�X|vv�O��k(L3���k��[P}\Wv?��y����
�������@�
=5���L�3�V�I�V�KLdX�f]��;�� 9���M-�k:Լy\7������v�8p�R�m`v�$�l�m�'��G�&�?ȩ�}x��4
��c��0�篷��lB��
T Ù�y��F��������V���}�rm4�}�]E�n�'�������g+��h��F�ȉ7��`^FVSG	ޟ�vYu;�V�D8�׵�sɎ(������c4'ڈ�]�c���5}<�(�HI�� "ީ�J��
��\��]����M�S�}��v�ێ$�D�����!�)ϡ�2":�dT�B�}z�3�+ì��>=�w�%�GG��h��O�k����ꊧ|Ϳ�P��� ޞ��(���һ���/��zmRd���VR��}5ջ�O5�n��j�� }����~�"�l��UYo���8eiw�x��+�N8����*8gB˘�<��k�Z�I���,h;f�ț>�D[4-��F/�#]���=Z�<K@C�BҘ�aX���I�hHi�=�9��$�Y�a�P �uȼ���*�Q 9lb>)W��4zZ�t���8��K���*��x������GY������udp�俰��>�a�;�NԱ�pi���q��8:h>>�p�ʙs��~�3��9�&e��2b9%ai� j�qNǹd�����T���=���>��XjNeWN�0    �ZG�k����U�2���G����gp�6���u��<��h��]�2��4{�?s��v)�v�򿦾{�Sr�7a�k��!ݩ�m��Άk7�Ǯ���������^��Zg����oƸ�(�d��K��ظ�l�����j��:y*��<F�I���1�K�HK�R��0��C����;��'�K�(�T�%,�ď$�9)�fq�r�����88���mⱁA��Z��M��w��Bk���qϊ1�m>q��[��8`�'w��N&�&2�}:��qq�SIj��g�s�m.�vi�]ɱ H�hu����.������
B�uw-�غ�Z��
���N�:RdZq)"�K�Q"�!��.�Y�*��H;`7\���?W�^֙C��x�7Z�4!�m o�*O2�<a�	���>��� �8��_g�ۑ
�&����.&�[���v�X��S��i(@Β�H�$��'YL�4*�̙.h�8��R<��7�3��XU���j���i3Zs�Y��c[?��V�����*���w��=��u��������������]����Z���o����%G	/r"BP��0�$��B�<��t��T�ɋLtr�}���g���ai�)����v�>gc-��r"��"q�o��au'8�u���T�`�d�D�,�D���9f˒��(���!,���A���x��N��5�M��]��}��v����/.�U\��6)Ȧ/9��:B�� {�ҳ���H �s��\2�1���)�Lϝ���O_-PnF����|;o��jGJ=��9ts}=����J� �9������� :v�\�&�3�`gA�d���y�7DlM/@��}��jvLg���4�s��^Uӹ�Ŝ�GH�T��Wl'c�B�J�P�Ii�LcQc��� a�ǝ��di��W�Dh�*c�jYҤ��,Q�Ey405EbqL"r/o���?�8�0��I�Ą����Ӥk��Ɏ-�����'V�2:������3iM�uX�@P���-J;$? ҷ�tR�z�����L��e�@�5���#�{ς˅���X6��-��ݢÐ�����/7K\q��y
M6��4	>��6��|;�T���sY�0��Z���x<{^j�H#�Л1��LA��)Þ�f0>�N�������(�ͨm:����)P m�M��S����(E���k���$�v'���о<W���_^���k�2��8���x �v�\|�6�-����b)�*�e�[,@'ȳ��Y��2)x�R��i�F[���}���bk�bÈ2�U���� ��5�K�,�DY�Ne
$�G��H�D���;�n=��Ya{�<����2�:"��N�
�ְ����+:X:}�롏�O�ajb��{`�ݍq¿�y��9ٳM!*�#�=j��y��2�|��eD�,"1���E�Y��p"��}�B~|�~�Uq��F%����m�G�f�����)�|7Sc0���7ewv֦�ц���4�B�-)�*]Z���J�$-�L���r.w����/��␈̉�w`�훊�jO4~�x�|��Ը�n���ۗ?`��pOU�{K	7���x�e.��|�8�C�'�ܱ����Lwnȇ�Ćr��Kw�߭�yu�|TP*OJ
�e�#q?u����|�8�x����?����qq�����>�5f��\�P�7�L��5 EF}E�V��2�຃t�6=i��H�S��k�'6�d�kX�} 7���F�k���6�L���i�մFI��+����t��ʧ ���M�Y� �Q����7���M@V����Z�`�5�Xkm�P͚"���oq~�rb�A�q�d��r[��͂tX��0A�����Dx|����yH��s4.F$�)쫄e R�����5�&��pr��y�}Ŗ#l�p|�(�=��#J-} P��o$��ir�P(��DD����(	AzEH������PV�h�´#��~l�ʰ����y!Ӑ�$��U�I#�I^���R��߶�j�9�r�A���>5c1��vNw������pǞ���m�wLN�!g�M��nv����ܵ!)6�N��*������P�a�������q�3�����j">�`L���<�K?�����[�Fd�iC`�-�W7܁�e��
����sk��0��T��_�u͂�����;�!�ޣ����-�����H��T�T�1�K��x�i��Х�~"�A�~Q5~�1p?W�mp�g��'��Q�~鋓�C� ���(SџB�s�D�hjQ��;�#�l����=���؃��ڸ��V��p�J�X��#kA�ȁ="�I�0�6I{�a�8b��r�_;;Ñ�?|wv�/��4��Ѡ�HN��Ű�EQ4A���Q���M�\$V{�WP�㬊���v����O�� ձ��� <$�F����c}7 ٷ�N�����x�7�l�6�D7P1EAJ�q�MP�T�DFZ���D>�2n�Ƀ��"��������d{qs֎Ц�+�����oB���v�G��ࠉÇ�ƃ���4އ���v I�a��|�Z]����ڨ���*����$��~�a7o�1S�O1zC��&�Ɓ '�`�B��5�f'R%	8Ҕ�!p	�@�YN"Vd\g�H�0����8����lvT�q�D�|1��~��1𤖰,H(�>m²������CGM4�0V��\���@?ZQ�,�U��;���4]�C+�������c�4<���wҸ������	���~�Ϣ�8ܶٹ���xw�KP��q�{L��ĥU4�����W��ڦ��N
����c����߈a��?�,��eh�7���s{_�!�r��x���h��K�˦�������[[4����HAa��������n�_�%��!�M�k�߮�o�"�x��s�i!^�<`oI��zc;��]:!Ϭ��;RH��x��lG���N�_���9\&�����Q�lx�$�������}�r���s�����knE�V��6�6�V��b���d��Ёb����g?VZLAu�Ă�$eD�T�D��HYdy��=���X�&�]�heZ%����c����V8f��=U|����ڲZ�ݺ�m7cL�[m7j�l�����YO�����1&��t�V�O@���\�T7������*8%��K�I&"�*�(�
�� ��:b�^���d���a����X�����7<	\Nh�6��Yp���CEPg��I7�~�v�e�|#d�X}!F���IQ��p�i7��p4�[k ���V��-���jU�d�	8���8*�|�'��mb0}h��4+I�Q��I�K"X���$1g$VJE��)˒��'�κ��r�	��b֝�k&�����Xhx�41�eX���$-3�tAK��E=�K�EB	��U�+���o����;`h��t���`)	��D�!�jBy!q�⬨Qv\�^�Vj͌oV�.ӆ���U��m��G���,3I�Rb6�$�dQFR�qJU<��R��Z����q�U;���f9��7�v���_k���~)S(�3���-���N0٠�e���7��2U�Y[�n{ct%��a��J�,��[�P�DȂ�1)�0*J� �}����Yo�h�Ғ8jh?�lucy�Wy�y_f��mu�}ʢ�����I2���{뜀�nm�5�`U���i���ϛ�ms�����ȸ72D܎�30��M�����ֵ0�c�R,{d��(���۰��m�@1��n��K��4E��	��f3�I�"8r���"-x҉n� �P���nL��r�w��W6i뮜��.نc�-M	�.�qH���$.5�YRbY�Q��aIl/��zC�%g^^��+/9ËLb7	K�	6@|���y�BJ�����.��	�`6*v	��'�߾{jʱar���jb�Qʮ9��j�F�c��q�;��b��U<1�o�k�-uHZ�/��ҭ��۲Z�[a���e����ex    �s�t�E����TەZw�	������&Fc�j���V�HGM���p֋�Qp0c��Ϯ��Jma�l�3���Kf][�d�����>W.��p��z;nrC2�������YUڂ�h��8!ؽ� M� k���T��A�I"�B�.C�k@�퐥,ץ�Q� �!!X���
�j��̎���z
�M��c��ӵ)ƍRu�6�Ķ�$��-��nT���=h�5�r�j*��:
Q����'���p�69�/w��(5��0�mXX�-O^sD�/����VJZx��m��阶[�qQ������m�����D^pM���P���t@�!4δH9���H)��d}Q��䑄�ٷ`Jh�0�W�*�!�& ��,�@9ꌔ���#-�c��@�؈�2$S��yTaG`!� ӿ>�p�U��uʘ������%0��Z���8+#*�H	:x�An�|<��K6}��@'*T5��&4�	�[��r���z�蟁c�6�y��Ē����(�`�ܺrF�g���ߕU@�@�:�� ���X~x��j��M�A�p�s�(G*���i E'3CH���h�p>`�2����B��S�r�]��M�he¨�M��7u��<e6�P�^N�Ph�a�b�� �:0c�(|�#q�뇌�Bw���E`l	���|��غ]��h�F��fC4��RgA�+���~����ݍ����JM��+ef���QM��Y0tF�3��Iǁ�`R,�̛���Uz@y�V�j�X���x8�����۲�2e<e)�!��А�4�S/�8M��T]�%�����y��@#��@�V^�����v<~����J\�%�j1�I��%vw[����2��E�GC�Ќ��� mi����P/,�����nǍټ[�ڝ�I����l��͹�ݨ��b��x��'��4���띢�m"��WK+�,K���D�眊��D�Du� ���4�˒����΢����.趟һ7׷Œ0�M�'��V��F}pB'һ��-`~�I�d^�|�y�|`G���VQT6��=�	Dk���?^a��[u����S����N�<�Ѧ�k�G��U�֕E��*R�
�n*8��E�<�\�2=�]	�չ�����Jsl������h�ϯO+m��H��uUZ���F<<6ma�&��n1#��4E���g��;����{'�y�	�(�Fz�i��6�-x�Ih�\!(�n.��ê�ոGV��t�3�1b�~Q��1|:�����ZWt7�9��vC�OE���*���MQ\`�{�4_F���xt$P�.��l+o�L-����r�4 ����"Q��`������`ާ�MF����|�N�9�7&��{[T֓��>"�ļ��ޙ�as�=	���@�-�`hj]i=0��ExSy��,�$�	M�*b���y�A��a���vD
Z{�_)�H�n���aփxD� �	�Mޖ�)�@�(�#IT�t�SP�t&HZ�))TY��6��V�]��m�aD����y�I�5 �P�dG�{W��.]$q�T��u'��i[�����}g�"��A�U?jGbݢ��۵=�b��rB�X���5��^�����D~"�~�l��7��L��z������l�t3]-���g�e.��Z�s%"�@I8\K�%1��b��c����\�
�u40�7�M�j պ���?7���u"�T�O�&2B��,�D�$���Ǳ�������G�Ʈ��X���/ַoJ�������c��O��>������B����c25WULI�r �1�j��H�i�!��ݴ;�D��a�8���T���� �����4��	,bQH�tJx�i
�(3�#�e��Я��BN�ED1�?C|7�M7���`v�WQ��uZ�!�
S�:6�&�r��7�x:��I����p��
�wWm�#*p�#.Dc��A��5���6�;��}cX��ް��L�ֆ���$��ae�D�����,m\��yՏ)\qJ����s.d��:�:�%+E'�wl��ﳌu�[X���ۏ���v��*bT&,����&"5E�h�~恽���T�B�
��`x��ôw�k{�Z�C]t/rU{��\�q�9h]��IP���6�ۙ����6�i\�8��ݱJt��w]7�L�Q�[����]B��
�����d���%��_�kc��@3��7��%`U첕8��'R^#��"�R���g�(�$$�-�RP%�>��#���g��V��_c�{�l�����0r
ܝ��~E��wRS���M !�q_�	�G?��|~8���|� 
�<�$��?�\����C����) �H99~����[lu�ʠb�GD@�ت�5`���A$Ċ-W�F�m��o��zC�=�B	E@��$�K��K��(�)��2P2��YP�j���=^���y�j�9�~λ��4�F��&��cfC���%uw�����T���Tg\0B�D�� �.(H�"�*Bi�>,D�kD�ܓN<8OƠ+�Ȫ:0�j9~ Uǽ�G������D�&:j�=�~��.V����������v��vxt$XeC>���s:��J�VXۡ)<�I�V��st��A�_eY��iP���&%gȉ�{��x$ə,ʘ�"�
N��(�� �fq&��Ѽ�E]��Kk5v��>^���o4Uځ�_֞�NB��E#�����L,@g4��A_�i�9Z�q�����ؙ���4��1)�v���v �РY�@AUFD�@;� yZR�S��|'����?����A��j�N�V|䛾v���ZĵԳf�B=w&��A߂�S����z�`=ݬ�Sb�ӵ8v��\�:;���5���s�7��k�_�ʍ����;��8���ˏ���Z�~���/ߣ@�t���Oo?�|�D<���7���~������Oo/��� ���z���������EQ��5��[$wNev�
S��p5��5�ޮq{ܮoP�S�u�"��j*�L�X}#!"��4�H�ZŚ�ݐ|�"��x��+��j��qܥ�C�YVE�����O��'G���.>�<��JY�a�X�w�zH���uc7N����di��0AI�5�J�������ǉ �"��A��@,�.μ�q2���1��ּ�w�ؘi*�8��-�	.N���w��QL9H���clmNR*B�XT��2/x'2�	��
]��r�f�#/o*؅3��u��'߾���B/�j ����+T��6˚��h���@m�$N��f�\��J�PX}s�P��=G.�ˏ��m���� M��}%H&��M�.�a�?��� �s�{���� зJ��a�F�s��nh�**�ˇ��7�:��,b*KP4�!YN��S)h&E�&�8��X�G�x��Ã���n �?,t�5��ѐ�㏐��]�(@��z�[�?ix/�$%�]%���-C�bN�"J���L{�o/W0�^��G���V�&�V����T�||q�~��ۂ:�<���k�ӿ G�o�=<��PW�ʂ��J>�v��������y�v�ec��iZ�k`�i��wH��nG��ueP���+�cN>*;�cSm�Df���fh�\��ۛ�t�;��X�,�1�A��_����M9����6U��}m��;���1u�t�y�k�4����p"򦒐���$,UDD�5Ia[D(%H{�ځy=&����At�ċ�z����:b� ���!���8�����g��<yݞ���c$...�$]�d��E*K�%I��A���$�2*x���m�,m)YG:����jIߡ�]s
jE�ula���Z�p8)��h_Ǵ��T�6��T��,�|�!9� �^�+�6�q��%(�����=��+�8Ic�N�
#�4�����(.�ԉ,�������.\BW�7J 띣�Qid�����%Z'�cD9����
iS;K�h�Q��",J��3�dY�2�e�"Q-F~�^&�^�������+ϼ/�H�R1��cI�Bs�k�"��4��SÀd3�~uh���Zc1���jc�M�W�?�    ��MP�_O6%��`(eZ�X¼�R����$�$��0���Y&F4�"�+��|�YBzwa����?���# M$v��b<0�X`�2�YT�P'͖�~��q���*��E�*O�3�RáLJ�"]`�kI���p�fi�S𝸰���x�'��f�ƾ?�S*�Zێ˩�a���I@^�m�(��J�6D����v��s[��mx��&���K��W��ޚȴp�f���Y'��"O����r�Ô=����jư�`(a��I����Bҳ�8�:\;���.v�/4ҦvbP 	�S��f
�8$��eH���/?�h�Q�;^��t>	�D=�wT�Ýy=�����,�]���N��o�BX�{!�{Y:_�H"y$݊�4<G�>͈��G�`%����]p�H$1^iK��*ZXn�l-��.Ȣhŝމƫ	wS}����:VƦ� ���9bT6��+�8��W��&�������u��J��6�R�D�0cX��X�F��.���Y�sn�I��4藱���[^Sgݏ�h�u�^�����k5<��6z�aV�e,B���v�Gm_|�x�����n�1I�ړK1���\�r"��ؐ��o?��u��름Ycַ5a���v~�G?a���O?���>x����8�Η: ݩ|ދZ;@U�м:��Yy��j�xD��L`���/����è`n����/t�ϗydr�y⳯ѮMUΩ)�����g����e���SռW�u�~��u�����bq�x���I t�u5�ng&h�c�A����T<h,����b��:ȯ1�<�Uek��=��i���˅�;�ԗ��{��cI<��J(IC�+�1�4��1�K��yW��7�<���lP��w`����tee<��Ei������i�h��	�>c�&�+Nfz�n�3�:,�=��j��VfXk`Ы����)��&�,�(ŏ�"Y���<��T$�<"��TJ�T���P��X��������Pr9M�Y.�"+s��$"K�L$Dee��<)���2��_/a�6���K�!)"�#���	֓"�Z�������gTFx���(?��d=�T3@�ns�O2�y���JN�O �"V�)ay&��x���{������F'�X�լ_]����M]M�7E��i2��X�L!�_�b�3�dQ�Fj���J�:�^�P�7�����{�S��r��n��+$�NsD����1[(*-���[��X�̺8��ٖ�[#J��~D��Hy�Ţ�H��汌�g"��2��M�'ߨ	���Ձ#Mku�+����:��f�b����<��1�TT{�����0VA�8m̈́�����j;�#�ט� ���K�up�_�6&�bs���ܪ�fO���G�R��]�b���ud�^q��%�u;�}��m�S���H�����ިhmb�n1���S6(y� ��J�.(�+�~)sL���02$�i	�<,R�
��I���q+���)�����)�W�,҅������I8�0E��e��$��Q�yc*�(�~����;3�}�>h��tF��AZC�CU
M2+PR�~���	�H���K��Oh�ތ��S���l؝
-�.�\G$L���և~�~Ϣ$���G��P���Nݰ_�a��g�Z�(�d�B�/��,J8��D�"�#J���3�.�
9�_�Tݺ�)g	�cJh�����T hy�T*�,Κ2cns���$�W�q�K�d)t]"��咢NrWb��,�[l/ĩbY�D��E���=�E%��cì,�r�iMxO&,
���.彿n���s���ލ�k�]�m>�hX�`=��l���\t���H'�YHJ�s"
�IP��>�y�KX$��Đq"��;�����fV�:_�������z���lF�hy��y����*Ҵ�U�V��: �1��F�B���k#�x�jw~��Q��I���@��V%x�AҀ��8��dcUX��P���l���Z�]�=�9Y<1������ŊO��&3%B�0d�.�7R$	��q��I`W-z�����n�m{�'���5*O붪#1zwvQ��Mm��j������/�����($�xgtG7h��ʜ��ǃ��23�:���n��� o�}��ۛV���a�w��S�v*Vɣ�������������p���z�ণ\^a�aj�[�q�� ��������{��7��R�&EǴ|7<����J�PG�́N�_�u&�+�~C��V)�ƃǩ"�!<@ĥ�Rl]t��D���@绬�э����>��X��s��p����[�7��tD�Nrb�z����?�Յ�jzg�V��#��P���0�A�J�6ch���Vw���﫭/�`PEU��6�ī�`�ߢ*[�O���bAJKdZ��i,�"��U jG���-�D��">	�:y�ൕ������h�Xf[dk��@� ���ձ��0��
�g�7��`1�+?��m��ku���m�������u5,qt�G�	(:GHw�Ji��B��]<��gu�Y��P�w߳�1�"Y$C�H��r�q��L�I)e�g�r���:[�ӷ����7}�����.���Cڡ���I��ZhvLS�:�R(�oWݯ�~�]���֯@V����N�ط�f�uZ}^�j�r��&���2���&��T@Բ�1-��=��&Y�2�<aE!r^�Ǣ����̫��2�{�Y�^9r:�����{�8���kډ�m�Ӏݶ-�n:�̛���MO�E �v�	�
,�v�jǷ+��i��)�=��{���mR�틻qj~Zlׯ�wKپ��&���=��ǽeh<i��	������IF���d���%���u�M�"��Rt�½�KH9�j��P�K0j9��9P�8�"�]�_W��Ҹe.�ꞼQ�k��J��`r������� �����SmkӖSQ��9�y�<��]T�j�<o��J9}��P�x���6��֨�K��5(|7˩S	>`�J��*Ϯ]��P��q����]=7�/�w]�M���*Xc�i�a��j��U���>��3:�p�?�r֧5(�x�[Um��t��Y�ԙ9�A����Z���}8��Qp��la�ERQ�>�DHI$�P2��R;���e��ny�g ��A�4�\<���/(����v-{X��	q�O]�NT�p��\��Z?EcDp|؂��Y�¶֛믥�����8!YAay1�7U\��Bƻ�;Gr�<Ґ����y���y�Vb���h���+�݁�"Ag�d5����ֵ�P[��Q�X����E��h���6�[L���E[�M]�r8�׽���;�|�#�J�T������߯BBY��DDe�����?�U������*
����]�t8��Y�U���0b�D)M�䅖��a��^�q�X [��5��ZV=XK:z�\/p�հ��GU�GW"�����v#G�]�/�x�	[�d��#���
��HG��<�R�y�SkNTkӄ���	�bؽs�q��q�M�^zSiX���R�R15�"�w�裹�V�R�a}k���q��v�X�k��� "*��Z���:��DK���D�y���`�P.v�:��8�`��&#�[Dhj^��(����%RP�A(Al,9��4!2�YRzhɩ�A
�1���nL���� f�������Ѳ��g�:���?��[t��鯫�L��.�_>l�_�����c����z����_L��-:Sd�T��P;,ᒦ�B�>��f3Lkho�eR`Ė�!��g�'c�":����~�z2�1,�b�-��ޢ��u�#F /�)�ws]p���DX8LII�6YX���T*g�(�g��L-ZM��<�v᥀y.�bW�q��\�/gu��M$�{U��2DAw�:��{���A��N:��Ơ��7z��`�Wۙ&W���o���~��3{��ʣ�<����_G~����$���7��o��������t�'�����(bxw��n���48l�mh��Mǭ�ʲ�Ӿ����{��r�e0�B\U�����+<���y���۾��� ^  ����B}��F���I�[�q������_�5P��&�&Cﺨ�����E��Ϛ�o����O%�����K�0���V��r�����X����ėg	lm~��6mF���P�p{uϤ�L	��, �7�t?�o�	0���ej
������!�������,߻N"`�D���������N6a6ħ-��	�i���Wޡ+�QY�T1P�"ϧ��ZDDơ,�*2ƓQy�?M�g	^�)�c3S���`�@��'2�f��U%����1���٦��5J���1��&N�aS�4`@~<VV� ��7y����Uk��L�$�J�$�H"�n����%�޳tЗĚ�sFI�w�p9��CNJND���i�H��CT��HgE�-.y[���ؚK{�;����˅w�ۯ���ڋ0Fd�.��n���{O�#��	u���S�j�˰J�=�v
I��^l�{D{O'�Ի%>��⎛� ����t���E�2ܴ��٨+P��x�����il0�g2"����K��10�ܘ�L�VO;:�&���+~>�@N��Va_�X�r7�o,I;�u��{����Wa��;]��k߼l_�c/H����#^���h�E���)��KÉwj�p�&p�v�#��&���ψ+(�d� ��2����dR�aA�(ʉ̲$,Y��<�&�,�|�뻱��p����f�&Xpq�A�wa�"����	rQ���qk��������'*�T g�I8L)F'I���C��<,����U|6('	535�a��^�=b�Ե���?H��cs�	����)0��K��Cm�0�~��N��yq%�jX������Ź&uj�>Z�긗Wu���I��S���v۾�=�SO��>�x�|pkv�L[����{�gg���F�sfJ�Mj���ZT}0j/Bo���y���ݧBsqtgZTˤ������t������Bޭ�yu�|TU?�4u���A�ɨ*��a��(J��(�aR.b����}N�F�g����5��B]~���y׹�U�������*:.5� 9�j��o�\Î:Q��4
Kk�+��ȣ�d
����B�z������2�)#3��=��n��j޺��_�v�Mw๻t����tޛ��sy����FL��FF�@�̇w�;���u�q4���r��֤��RVն1�<SǸ���|�>��9ח�f:�/����ߊw��_ni<\��9�v�W����բ��>O�8^O�7��U�ܮ��� }��9f{w~���|����6ks��߆�O���FƩO�fG��|7��Cje��S���،�{�΂���#2��1��_!�3��]�X�X�+�>�@4)LA3p�1��0H염�uU�"a��!)��2��P�DL�Lǈ~��|u�r�X^��
q(D�F�=�g@!
�P��^�X���Z	ò*IAe�M�R�Nx�c��Ę��Yc�{��ų�48&zB��A���¨L�e��qNE�B�e�B�"W1��ў�c]-?ge���"���35JdG����Q<Dfp*���g�;xk�Q��_�{9uч�o*�����a�i4������%�i������_r�? |��y�-q\E]_��j�!���+{�E��k����-i�ς��;�F�U���FX�����F)�L�\����A�JsP%�ݝ�a��N���{8�=M<w"�\��D)(3"*�kq!�W(�(�b�S��������E����iY�8	"$G@�(%I$#�j]fY�u3E��U�?.�f��a�5�d_��e="�/u"�ƺ E�AAmW�B��<���<MGa��+���E�:���?
��#�w�BgYD��>��K� I�p�򸐩� )B����2�}̕�^��ǫ�XfJ�$T��cMR
bMs��a���]3~��&q���Ga���y�l�
vJ�!��l�����Z�9M��hk_!��)��2R�H���V˵� e�=U^�u'n�4Q%��.e�����18"	E:��Q$�q�|SK �� �	��C�DX��וM��Z�o��_n�̹JD�jq5W��d4�(*)�5l����eU�B8�\��?fJz�	}�� Z�'5Y��Tq�l�hFw�+W�u̪u����!���p1HWG�����h�B��������HC-|p��V6�B�#P��C�w�Qܤ7vlBFl�H<�A��is��Z�n�5�?ZTVj��[�RXR�;z�{Ś^��V��O�� ]G��I�s���J2��8�a�I��^E*A�i��;1��N)H��7�D���_GmR�_�b�(a�U�ս������5ҋ%>JP�#�3��8�!��d�@��(/b�G�}\M?�3w���?��P���(��Uӑ�����p)ܽ��h/d�Ψ�j�6(NT�m7���Àc�/J�|���|���X>��XcY~�A���}%�Z�����r��}Ǹ欩�Gv�V{-�E��>��3��W���)+u���L�(�$	Ú��RDI�IN�H���Z�]7@��1l�PW�>}��� �������撗�Q�ƾ�!�,;�g��˄	�:�+q�`]�c��k5?� ��EIŸ����2e���ZsU�@U`�ƨa���b;��L��s#Lڲ�^��3h�5�����+�at��2j�i���B�L��mԶb���/�v��D3h�G�� 4����('����if%��kN�H[���o���Yw�'�p	P[�}^o�^�6W�=�|o��F^nL�9�@mT�4�VU�#�<�r���z�#�C��2�9��$�5LGR�L&%S<hh�C׶v��Rdh4�L�_�>#�++í������7߲���gOa��9Ve�%Ie���øHY\J �4ɣ�#�~���\�.<TҀ��y&�ɡCu�:6��F(!�H\����0GN��(�y�'��<���N4�P�{��z��h����7���r�;4 bn@L�}b�>�!~����&�N���QF��b
<Yğg�i��,K�4/�[u-�uM��P[/��7>zހV�v�U ��jaPn�4w?r�kˆ���YB%��*�DEqN2�k�
�	w 8�
���q�m?���vqp:�HIv�{,����]�_�w������O�o���/�b}���y&��7Q�ØG	�x��f����$Ϩ��+����ЉT!;X�6L\�je�4RN���E1!2���1��V�P�VɎ�slf��;o����*���ݸ���@�Nm�3�ڨ�Q���ߙ��@��p\���坝��/�mo|hp���hPw�kԤH�ŮA+�B���q
�~�س� �RB�\ld"�3�pitw*���d��Z���#�/_:�?����o���ٜ�      �      x������ � �      �   �   x����J1�s�)�24m�6W�� �{�Ҧ-;��{��U�	$���'�b� I*�Yf���ĬN���60�b
��a�����t���N���W�H�BLk ��@�jwx�S%�xb*�յ`,�F&ל3�����DGv+h��7cSӐ+P��Տ�� O���&&%��+���bRc��c�g뭧&�?'8��Ay�^�[���m���ځ�����?!�d������=����a!(E[^�eY��Rd�      �   �   x�e�;j1D�S�Z�_R�G��:�4;����r��

�]T6�X�P,�,k���D'�:+��(�������n��=���$+`F�j�}���6�ļ�&�n�����`�j�%����
d�7�oh\ۈ��N��G䜁�f�c!���3��2RQ^��j n�O�\�n�Q��d&mfE�����fB>�      �   �   x�=�IjA ϚW�2-��sBrQ�t�!��M�C ԩ:G�E�!/I�� ](*DZ�����mo�Q�w]>����ۭ����~>@�j	퟿~h�hPk��bX�9&M�a�C�#��@�*�>zJZZ�a�r.Cj�P�p�]��̾ri���m�/`�2�      �      x������ � �      �   �   x����j1Dk�W��eɲ�i	��kd[N������rp���5�L3/N��`Lv ml��c̜�N�@	1b��«m�/[��v�l}�w��Mq�ʷp�V<�#�ԓ%(��j�VO.�	��i��3v��������EK�={�	��~�Z��u������5�B�s�jКN�F�M [F��U�0�z�m}��g�֧��m�|�?*wN/���م2N(���&� )v��
/�ò,?#cg�      �   z   x�e̻�0 �ڞ������"R�n�H�୕�L� .cІEW����$h����
��~<���Y�q��
zî]'�TZ�=Eh9��4�2fl}\�����P��ϛ����#?      �     x����n�HE��Wp�TB��:;'$3���$p�M��bd�R�@���A� -��9U�U�(m�P)x06 �-�,�anL��tH`I�C.K@t-J	�%���i�]m�O#������w������(�����O��ZH�֚ȆD��	`��*'�{AI����Cy~f\��[�q�gZBB��c*��y`TU�
DI����<���Z��=JZ����Ш�����[�LHՈ� E^Y�YɆ��\ �Y#[aN���sO�˴�P�_����������]�aq{;[ๅ�m�9&��
LqbF>�-�0^7��K�-�dT�-���!��dO�������ݰN�q��k�Wi���U̓�X��p��ʬ��	9�Ty��Y����*�"����h^���y�>MZ-�y�a�x�ǉ�.��wݛ�?��]�
}�׌ c��1�� �כM9^�p_�����O;���]v7eZ��0>�s|p-�-�@	%fnR@1�P��(���]P�/���O�On�7ڌ��?��F���M^:�2�Iɜg�� 9�bB�,����2��IY,ʑK�
�1�E",Ӯ��;�h컿���sG�����gaB���o�+��kQF�#x?G!B�Pو��m��,r����#�Yv�kyد7��G�WW��d߶G�$�������R��W�撅\�km����r�5�W���&_��ahQ���5�X�h���z�Md��o�h+o�E����]9a���y����6�RwM��c_����i�/۶�x��      �   I  x����n� E���T<��RiD�IC�p��}I� �T�^�s���w��8.��?ꀰzt��O��(A���źzY�7�����Q�L8·�g�~�����tB���z=�bpΦ���Nl���LJ�4����JGx<�e���	^p0z2>|9�.��#�W'�=�U��㝢?�LO��8��/Έ!^p!q*��	����eX��|���XR87Χ�
��F�
��`����W@��X/�L��_L�e���M~V�l�q�&��~���l��Bl��~��(�8:��bO"k7���	���ob��	�UU���Q�      �      x������ � �      �      x��}�r�H��5�)pyN�)�Ew�I�75���)O��.�B����̣̋��� A$E� c:*���_����ꞄaD�J������~I$�ѐ��jy�vA�|l����>]f��:M����v0�y8Xh�!I����W��m�]=f�`��
h:�<0�9�_P~M�kB�/_��ۧ?���ߟ�=��>}f/��>��{�����������i��8����U0���ӗ���y������+8��d�ۤS8�@~]�cuO�0D�%�)���&|@ȐF6�N6 ��Cx��������'!Bb��?��Yx��Z(��/߾#��@&��鯗`����� �+C BD#��$\2�x@"� ��]�ܥ�`�n��}����n��'�TKΐ2 X ���dh,'��:~�����k�f9`�8L�f�xH�A���͂�u��lW�8��ɇxMD=�\�2v��5�n��1�!*'%�2�0D�C��`�[�ٻ`�xk��!��AF�O���>��`��
D�~ �#����� r�ß���}��������}�����1��Ƥ b�
&U�aL���<�]��Pf��}D�� ,���\Y4������t?���j쮸@Q���\� h����ϯO9s+��?�>������k��ӿ�?���M���-����,�\������Dn�l���)pهi��w�l��k�+��%@n���b� �n�o��YV%2I�e|-��Y��M$t��](N%�$�W�G`�l���z%2���I1E,�W��h7ڭ����=ƻ]�	����bO?����}�m��ܽ|&��?�J(
g�q3W$S�nx�t��.'�`����M6��3�;�����͖�fr���G�D���A�k!�K<M]�EY�`�!��4�<��`�[��<�i�?fHd|��9<$�p3	^O z��m2��Zs/���r,5���w��W?���բL�E�ūf�J��<�͕��lH��^s��q�Lk�:Rj��2$���
`����9V�P#�|��FEdI�hR�oIÖFmnTDhT��~g�F���K�zͷ#ET9�� ݢh��H�v��3���H�q�D�d9^�)�b�$9 � �7;b�8h�8s)͹VĨ�&&sxϛ ������\��N�
f��;C�:��50.�7�W���Tl�s�Dd���'��|�7��O��^�������ԁ�xd����'T���n�.S�h���Ra������<}�9b)R��\�z1|�X"�����"%�h��I��/�`D�	�'2*ޫ �dJ2�d�w�N���4 [�ȤO����f�ǎB�r;J���,F)<�[�S��d�f�s���� ���h,�����+�d�k�z�`O��4�����s���,.�O��!W��x�E���`�-�ȳ��*xW'����I�e>
e$�s�p��,o�ijI�Y#9ܜ�$��7��FYb˶Z8�a����)>A`?�)��l��s/˹W�_��`
"~��zP�cſ�Z�kڮ�T�y���x��(�Bp��ǝ��E:���s?N��g���ڃ�0Y܃�	�w[в�l�[W�F��y����a&�i�c�y���v��A	�k��2�(.*iCh�n Q�{(z�n��:H��t�����
�7��^��|a��"UТ���޷튦Ȯ�k���|��+> �W\�^߰���GE����-uy�*�<�I�.����2ZN�3.$oa\(�����V%1/^6%.�P�`M�w�:X��٢���}Ę��Z��z��58A����^�8�^��Z�{�]��
jS�x9� �&G��I �z�Z�1J��y,22>_:n�����IwU������s0�Uh]po��������P��AG�͇ȿ�^ƻ�nܧ�9x�K���`ײ�	�کUFF7$\����yA�Y���������f\���v"K��f������#�I�r���e�9GppFPݧ��VL�v��mjC��L��NS��7wE��U�2�ԋ���༣Kf``@��%��\'%���'���_��ػ�s��-E���ۿ~/?T
&��}ډ�R���x⢊�A��A*`Ӯ6��}M�e��DTh"��k��v�uޡF�q���p�bM������L� v�&�LQ�Ƀ'v�z$��C岨�8��Y�W�媤9-+�PȂ�����<&�FC�F�����R
|� AF�o��d
z�ڄu�2e��l�nנv�
q�pb��e�/�Ӛ-J�@o(YTA	jS�6��G0�=���-'&]��S���Ѷ�_���VI�P�+�7�9�������z6fm2k�&ye����2�(�e_̴S;Ӳ9b�"&I����}i�C��?m�!Vx�Q	+�`U�"!�h�O���b�m��+���XE�5A-3[-��Y0���Ed�~���U�>����Rv�dR����� ��:���Ò�ǝ�
�.F�Ğ��1^�rFSPK���w���Ӡ�]��"�Y�Fr���>6:��]̩�FMF+�nZyM�خ�xXB++h�}�`6 }7�8�@C-�L�C6��1�c����4�AZ��v�U�%}#��Q����b��(f���Tc>B^Z�$��hF5x�E8XƘ�2Aci)��DH��.|��4��j�����L��.�FN�P�� �}f�֕��(�q7H.M�A<oZ���4�-0���R�)�%�ݣ�n1b��e0�FR�H-F> �#�������c"I��7��o����'*{	�8���Pw�e�E�9L���-�2J��<�M6�샊/�xڬv�LA�b	Q/���`�ޤ[��6�߃�^s�We��p!i�yYX��h #J3mb���y�������@�)+$���Q����]��*�z(2̖%�{��e �o�����Pj/�'���������%ae�0�5�潇���4���� ��6P7�|l��N����I���&W�0�*O�j����Q�}9o(�Z⢕9�p���#eb�N���*i�i7�<h��ޣ�XNn���n��ݏ��7�K_�8�E�"0SV�H��/�ʱ��������±C�ѵ��"� �e	�t�
["^l�q~�f��y�ݮ��y�Xd�;U1�iPN\�"=��E�W����ŵgA:�÷�I�G2@4vjeL#��fr���Z�ނ���D?aY��E��W����k�>*��[�۽���G�3J*���9h�M6Y�ѓ�g���RJ�GE�����'�f���NU����;)_��3Vs����״���tЄ��q�$v�RtUedI� �d�2R�����S�IC?f|Ei��h�b9�E�^,'U.�]�^��걒(t���X+��!V`S���u�U�i��W��f|����FU�7�:�"c��8�EGe�D׮EF*��|q��:����պ�D�̠1�6�&6�)5q`�R@5Lȷ��u8��+p�&�Â7l�X�e���f���Ȣ�z��
�K���H,���p%c���z�S���vg`%���u�p�D?ZU�H�¹�^;��U��q��VUdR���U4�I���I��n�V{���]���f�������1��g�X�����z1������Hx�p���ۨj��M��ڇ�D��r*qq���&B+a�ަ�`���;zr�71?l�4T��A5�t��Ԏ�诞�\�A���puKi��[d��6�F�Q��R?��w�[ �h�I��/�wc^��0\����2�ʐM-��6��ȳ�f��E�`��U�Y>楹2���!����!ۢ�΂�\�*�9x��Q��1K���8� ���H���&�߮�:Câ4a�f����t�\�Q��^�X�\4�^ٖ{1�x��K��1gd�ض�SK#y��H���tH�P���U�Tg~�
4�U�������m��*,u�1���#xyF���I�I������P]��]�i�u�4j:V0�71Бp�!�X�mRC[�lFI3�    �j�Z�ꖯ1�ws�|J[̉T�
I]�V��c����@��䑃��f��5�?dJ�EC����Q(�4q������]���F�@��GJl���E#N׷*o��G�s<�XM!"c��?�.E1�X��js��T���Q�6�C㣥�y��R�#n��8{�Ri�q�˨�H^��+$��0�қ�)���<�6�T�8�luћ)����E����Y��;r��:P����5���WU�M���ɐ�~�D[�������Ԑ
`�t6J=���=e�jg�����6V�q��iu������f�1gۺ�˭�o�y�ǲ��N1-���fC�f2dߦ��P>���ed
"�A}#'�຃�X��6�d4��M�H��e�E��9�T���W��Y�Y�3�=�1�@���4CKc,���l\���	���=ƪ6J�@ �R%�T�|���	H%F.���J��Y~�<G^����I��\����ޟ=h'���Gu�et![*C��`��@��Y���>�`�m� ��O))�,U���J"|^�� ׄ��0��$�/�	�|���?�L���KY�]�[�Am��M��m���h��ւ�)E5��]ċ2��_���<��O�Tg�Y����`�h*nd�Y�0�=���ûr�csg���1;��Ԙ�X�˩lX��U,��ЄI��P�OТ�"lRX���&.�c���r�Z���*�b����;QXK+��V�0%��?OZ)�X��w*,�9vF��]p[y~z#+k�Ȫ��k�/�R��*!b��Fp��6~��t��q,�d%��E��1��e�� ��U����,@s0
)�����8�q�4�h��$�8YN>a���?n�S�+9Unh󀵛�t���t��W�:I��K �B6���/�т�ܴ0�ߦ���$�n3&���yO�f�)1��*��M���>�g+�$����Ɨ�U$�%��_��έ�`<p2�m|����<�3�gejqf)��J�ݭ�j�-8;��Y������ϴ+y�Ȓ�v���	H&R9�k��@����fG�̄5xޭzL�g`u�[���n� ���]����RЭ�%�?�\�Ũ���s�e�A:_dG��ݘ4'�1,��NK!V#�ưdT�,���R�A�d�]o��6���T3�<�A��ĕ����tt����ژT��i������+�K�N�1�� #� �Yg��W�J٤Kߨ�RT�WV�%TRP��]��Zxs�G)CV൦u^k�(%�'̪��7�
����H�h tp{�A+���Ƥ�W�W�ѱ���ơM��~�Z�@��01�C$�v���Ѭ\���!��'yZ:�M���Kw��2<�M�Ź8ٕ��mICj ��1�N(P&֯��>�ռ�xZ�P57��?���/!rI�;���-N}	ܛ������/��������o�k��5�Lǘ�ʒ�%�f�^�5@�07��X}v��>)�m?/�`����	V��`�ng/��kҬ:�ui%c��C�V�9R�`�Rz�i�[�2A�L����R�U�0�]��얄<�\=D�~�5�Cz���U)��9>W�⥉���[�V�oJ]���s�����m 08+U�l���[U���N����
�Y���~&%�,�#د�|��ӆs�[3����	O��`���IkS�E�V�4a�.PH�c��oi:�
�Y�BT^so�#삢�I�_�b�B"]�e�y|HU���wo��j�B�?t��ꧮ��c��C�m ���W����6)���h���f�,�!����6�����X����u�8׳�/�e�SZ0��u9��g���[|J�3DK�	�u�:S�h.�\���MMQ�Qz�)�FT���$�X֔h�`�mRkP�W�\}�zOC�I�t\���cmǾp�2K��u^�q�Qs�*��=ڷ��&k�����e)k�ƷT�2(���V��5��>l:+J��E�0v��5�z�=���ƙJΚg*6Q�m�D�-GlF��i�X0m֐q5� 뀡}�f�J~q�2`�0^���@�KE�С��Q��h�i[��v��P���&s�^z<�e{�^��K�*x�Έ���1�*����z�1�V����zsҷ(��;�,	�et6�`�����Y;���,	Q%t�^F��$�&�b��	�ve���J.~4��l����i���=(vĭx�EC��7��K��
8�J����/�W������!I}a��]N%Ƅۅ���^XK3�9��,y�\;f�����c��4��Qs9����I�A�O���R���dc��>��>��mv� �QCI�!�;N�n�ڌ�+�	Ϩ�!Ԅ.��f1��o���Y�H4�V�6��P�%H.3���j1��v�¥�t�j'�o��F�x���oE	m��e8�~�L8�C�/��#FY��۴^޶��56���V���:�}dYX��H�
h�a/s'Ė��RV������H���y5o��+Jq�Fm�4���":�����	9�㢸�i\�>��� ����$<�z�&Β��z~b��e���"��^SKi�9X`MZE��i	-�f�3��=�w8X�nYH$�^0���p�?������k ���B\�%�ox�j�h��Y�z���:a����߾�D��}�����>�zG^�"�Xւ�$,5�]�:&�b��o��TQ��K��&���+d��y�0	�M��8u��E�\Z���9Pq���t�B��{nTvS�2rQS��ij7цv�E�ɥ�7*{��KS�m��p�H���z�M�vFfI��)���Ys�����
4��Yޜ�GjE�0uo�ՠ��ܚ�C�o��epQa+�
ʖ��QY^Mo��F�0(O���Y��h����m�����,,�<Õܼc��Bd�*$2=S�����S������.�ڦ�o�98p����c��C���A�8�^��,Ԝ��*�۵����4l��m>���v1=�:�V`6C-I�1�9����u7Y<)HI�bd��_�%7���`	����P|^&,qA��,nlE���`�[+xQ���U�1�$nY�$T6Y��E��̬�Fv0�&j�jF��dqBԑ���a��[�Q	&���-� J��i� 9Z�{���M -��=� �̊r{	�頜6���K0m�%D���f�w�J���
R�$�lS�I$�f^j���̫o3s!N��,���-�ѥ�iv�]�P��J����e�b�x��T�iٌ��w��`�#��GvtWh���EO�q���x�!jL���9Kxq�aNk���huqq������t�ȸ��ִ�Yz�f���6���%���L�*���+v�%��JM�Vr���I�"�%Ɲ�XN��b��+�NO�-cE݄�c�0'���|����-8��U}��6�U�:3}o��h2FFv	���R߼���q�(�iEV��Jc)2<3݅������쓯=_rncQfε
�rź��q��P=�5������5f��8���k MuwS�MJn�5���_t�rtp����oj�^ļ���m���K雖��<�����w���b����Ho��d�?���t�����͋�}{nj>Es����;U۠b<W�p$�B�sb�K|�$+I2�>uc}%jY4�k��Z&��X�n�6��)7�_�<��0�v�&��\��Uձ��Y.�'� D\��������GT0�56�2]��*�	n��m�`h�?q����-����c��F�%}ӭϙ�R�g�������Ë�z����(7�U�c��o��B|���h���%עW�jÀ.M�`�(?}ŀ��Q<����J����\!mf���s� �:�L@�*��4շ)�O�猩ļMQyP�ؽ}�`W�{�3�����Ӻ���t>7�mF��*���q�ϛ~}y������&g�n��o�W���?f�y�Ȍqg���#�����|7GV�.a�k�:q	�ܬ��݁��50�8�X�)�Lqc�r;�_E+���>�!�j|��W���	O���xY����G*>    j(l���x�+�R����mjB��&�꼾$[�*�t�(Q5@��,�e�B��r���!��Z���-�;� D���Ķ��o��Z@��#X�v���E������q��Mk���f�[�68k�є����9�pRr�|^sR
N��M�aTq�����N��a�H۷��{�~��tj�����d7���� :���K�2�Y�w�P���MUa���,f�\h�X�j),��K~��n�X��`�����S��W'�� �t�)h�oҚp#����&�pQ��<�T�	�ux	�(�t��H�c_��DǢ94�1u2QM^��&�fnrx����0���i�0�nk�,ͬ
�����$v-B&bAi�Į�+VM�V��6���R]9V�������a�|�T{�s�P�&u�r<oƳq�%���9�GIR��t�2�ǁ���zu�
P�>�������z����O�פ�RV�Ձ��FV0~�IqLJ<�C��	c\a�-���ि�B/N�jIP���� ����Hq{�%�s�~+��|�)o���K �H�W�גyglwʸm'nh���ֲ��Vb8��²�˱�nW�Ң0O|EE�/fG��˲j�<�����e!q�N6��l��
!]���>֑7Z��a�D����	�&�*�!I��Mi���� n��s���b�I���q���-H�#�x��ջck�rG*D��l���P�P�����5w��]��Ʋ�mx1�6O�6� n3<�^:�N�O<��o�+0B��>���ׇ�F]0۷"��&�(�rH@���"?�/['s�}���u�n�d�C�Ӓ�j�8�}�Z`1�
%Z��nS��+�
,5d\r���B�0u��nVH���Te�*�0M�%�:�g��o1��g��1yJ<��U��EF���4��e����%�ϤoV�9����c'�pp�~y�����x6T����Z��ߟ��43R�]�v2�u3�N�Z��#�,�H�2�*�%^mT���ճq�$�����#	O���4�����*oع��4(%�R�LB������4[�v���Ȼ���BiѤ�6	FU��(���Iqqr��Tв拓Y���9T���	Ԑ�jF�+�|�j��6�����I�U(�e��R|�͞��T[���U��(�(ޕ�*����w�h���刅���#z�Pj�U�Xi���:��<�T�2V-2�X��^���i��'&z-^~��j*���϶.�oc�O��SR���QLZ��^s���U *9)�0S�v�A�*&a��*X�0&am�Fy��"�U�K�#6��s�ڌl�K���	,V��/3qJ9�L�c&��o�r�K�T�'��o�f��U|��&��6lܢ؞5)�ר鑔f����b2IзbX��J,M�Ae��
'>T�i�m;:ۡ+�5+��Z<�R�]�v�iv��]�w��iqbLOβs��z���iC�|�NO˩��?�~y�w���gP�������~o=[���勠���u3J�<�"ŤR��vv:v)��˞�{^!x����R�	Bla�K���l��T�t���)l�W��)M��m&��q� *[%�7O�Ţ���|��YQT�R=�V���m��a\�6i�5	���>L�Hn�?z3��(��~|�~�+D���-��W .��uB�˙�-p���Y�I�H.�}FF�/�sV�JKq6г`֫��HWˇ�p�Niʁ3@���8u�G�yI@h�d������[�X���uX�[��+�S��4b��6��sYB�
bn�9���O9[O4[�t�x��.-w�jX�d������R��.�!+��܁w�W�T�V���{zdP�Vv�~��ʎx#���q��ZU����uk9����@�o����L�P\5�|�oU!T`��u���3չ{;�lw^�6�����Q_�	6��,��h�~?�WN�s��0��Gx�38汚�Y��%�;V�����V��W{��"�\�̚�8ᭀGg'��B=7���[���xxp,��?��'�+�$�j\��z����!I��<Tm�@A�*��4�;���>��S��g`4UF����:{D�g�Kowz_��x�+�.��,f��َ���̂c60���`$\��݃ߒz�4��̙�VAܟ�-��`�����*d�Ko���6*R��Ą��s3��S��YY#v��H+"޸[�j�-BU=.��;�W%�r��U�B�m+8&�,`�]��Ж���p��=Ѹ�ڶϐ�����*�<cx���ꣶU�;�5�uE��Y9vXh]� �)
,N���>J-T21#is��m��P>cv�����tQ���uE}���fś�����/U��egͲ�M�HI �͌KE�\VN�DL�����\cz"̗��[����U����ns9%V�6�@�c �,�z�1njT�@��4�QK:�s[4�H��c��ﬕ����t�B�j�E�N�7�E��VC��0C����C.9D��1����)��C�3�!�Q�o�C��j��\�����T� eƙ�ֵh�E�^�T�|z�y�����0��"�-kC�F�수c�wAO�QAi3[��*��m�@-�X�}-���<_n��/�9Ptk`C�ܡ�ƹ�'ߨ����4ka@�W���3��q(9*�n�[��C���y(T�1���5���[t�BS"��ի,^�d������5DQq,r��t��(L֏K,*>�͖�WG<yU�PƳ�`��p�aUhla襁�HcEqI3����nOO0Y=��7݂S�^d�Oٛ�*e6&���ᰅ��E��+���J����ܑ�!�+ԉ,�+�-]A?�.OL��R,��h�<��˃ ͜+lv�����pZbӸy�k��7	_�Hc��1,�|�%i2�a�V&�q������2A�z�W���q�F��}]�]u�a��m.��3;>��6��߳ͥln�y)���vhn�}9`˻v^
K��ǢR �ń>�����a���f��-�$v����i��f�ZZ_�y�q�6�iH�5�"kc�3��6��y��h���Հ�4���ie%-�#ɰE��d\d��L��nQ�R29�oI&�6���W�٭#�J'l7�X��E߯l�u4`������*�T����(�ʀb�(!�d�.-��
�"�9�y"��ķ��#�By?9��#���v�;���I�O�~NL�#Q�"���X�q���d�������SC^}i��8k�sy�~G6O�-l�{�^5�&�����ϬW-͟;�^U�g�j���9��֠�֦G�Ԧ��t=~f�S�|#b^�|Y�_/�c���uLxu��A5Pߠ�zT�q���l��a�B���,>d�ó��X�g�C�D���ݠp����0���X���������	V] f�ׯ�g��)�k���o{_��M3~�
����#�_��;2�ƪ5��	_�r��Tm�iä2i�T6�E��{�ls]S�}G:���tם6sqf����2ʍKC��ϊW�=����t�M���\����I�|�䩳ъ�o��ܫ���E�f�^��Q�r/��U��B��Q�K�B6�p�8�qf�������b�\i�m��>�رP^�k�E��	+��еP$23�j��x̼��hA}.�Q�!8��ki0�����8�a��E1���F���\H�Oϛ����r��,���1��1ܮ���dy���,��+�D�)�N�Cs����1��bԶ�W��gDm��9-���
�y���E���U�Ӳ���p8��d��.#e���	w9\Dm����шm����	/�9ﰞ��J0~��#�`(S3/0�+ gV�5��Ц�hG�N+!aBk��9�(�]h�X�D�ά&im��[ ��B;�j�T���6i�b��	�E���u�����o�ii��990X#9H�t�8Hon��z��]�&��V`�ߦ*�#5�!�[��4�$��2�Y��&�0�.��=j�K<���,�:Y��<p�K:C���w|    �f�t=%2�Qr�+(Y�����x�k~ށC�l�̦�4q)̈́l���M2�zj��*�����b`1���٧�����БjB�l$ؔ
�=w	mф�Մ���칈ĝ����Z"[��ZNO,���݂���*��@m{$s�z�/CR.��c�)
�
5� +-x$�Lz�ߌ�$^������:O��n]��v����<m�M�}���m?�Fv�e��:bؐ���<Nq��e�uD-�O\�j�������\�z��l7\�WY�L���*���U�����d��̈́m��&w-L���q�~�M�{t��	#^bl�[�h6p�h�9ѕR[F��G���t��B[��5��Qp�=H�@�vs,��u����v��s�>��_Z!5�HIOK�1�
F�~�i���?�T��������ff�<9^�&/M�k[ܬ[�.t*�P��$��Hæ����*0��	8"��P@v�e�8���m`(�ۏ8J�G
�Qij�^�<��O�k"X��F/�� \y� \���z.��5��	<⒔&����c!�n��D��|��@��l���ٕW��|.�6��G2����}����{0�����f���BM�5.&?���>k��X���X��QKx�:�`e�̸��e�f�@L��Z�7rI/�ӽe�O�tf�Mmw���ړS���t�K#��ӯ/�|����tf\����������>����7�����V_�������ɇ��2�Oz�"�nNK�ٰ��e.6T���t�P�����Ѯ��N�j�X����ɵ���0�����_&Iȵ�����8R��=~� [�~�^����@�P<=������ 	�3����17�u����	�}��-_��Ȍ��,t��+� ����_>������u?>��������	��QdZ=5���%T�.�B�4*�dY�d5,��>L������?D���^�p*QFEYhQ����)(Q�.0n�X���_�������L��)a�b�� e����)��#L,9]���=D%�/1ҥ���6'M��FG$]����o�R�g�BY"��_NR�o��������c¶��A���C�f/������u�}�\97���iuG�0�(�B�'��:������/�z����M����"���3u߇�/1����;=��b抟Av�ly���%h⺉����.����������B;�J�S���::<ɦ5])��r��P6�����3��ؙ5�N=7v��i09w-0f��y����n�97w�?����O>7�V��2���ʊ#�D�L�&j��C�}�;e[M&o�H������w��j��ş/љ�^�����u�����=�>�G�M�C׫�Sy�_s�:�=/&�6���}*/r5t�'�Y~Δ������=���CO �[�J��P��O3����*x����9�_`V�X\��m0��/*>TE�Zx�޹nl��>�}�����`������N0��X&�_Hp��5jk�w� ��X{�o�A�\*�X������B1힟������� }�}�u��]������}0ڿ���q�KU-��l�.��P�[���`��t�C_�9\��l]�����|<&�0#�w�d��[�q"��M�>0��alM���qmL�4l����`����]���K��^��Uf?<����˗*��Z)��H'��P7�u������?���\����G�B�}ZD���4*�zemMP�&H�w����N��}ܣF���P��C��;������s��,G.F�9��a�(/T ��07��&�;��^8���V\p%���z��J��	������>������!;n�/����2��Lb�y�Eφ���'���ާ���h��r���?׻�g����ܺ �Q����ɱaL�&��'���rH�V�1����s$=�@tto"�'x����5Su�Y�`U�����/W���P�K<�{��Ț��'�7u7�Ҭ����;��b���oA�Fb��^w�u�n�8q�	QϬ�_�[ �iv͜8��������F�kY~[�M�x+1&�y���U�'6����f��a���0C5CП�QpD��["q���#�j�\��:����&�����7�|(q	�H�H������c��8Rub0��wŦ�U�wv��Px�*a0�m����������<��}��ח/A�����M�:B����%��.fWaﺊ}`p������~��y�N�%���S_lڸ6��!
I}s�M��G�S#p`0�<�.�ՠྚ�.C`�dx
n��>�U!Ƈ�];6e�$�5;�{O!���'�C�l� �9zx�;:#��O��D���{�����/�H�G��ǯ֓�����9x)��������w0��_ފ^h�R�-�u�uZd�������Z���9umYl*|<mQ][W�f�8�{X��T��I�0ֳ_V�^�(�������7����Ax�q~Fxİv�A\ �"̐��:: �m-��R�:o(�1�r-����ˏ�����y���DR�b�*�{K�!Ŵ.Fs@�i)�~^))��P(Me��x"5��M�%�I�"��������������R�����R����#d�䡥G�������X%��O}~�[*�-C�,��Y���|MV�|ſ����<}�#4a-N�2�Q-d8 Ʈ?]��Kp�<b��8*����/�ɿ��|B�q$��0����o�b�ۿ��v  Á՚`����3��V�Szk 5l+�)�q�{��H���TZk/[����������W�]�(d�ֲ�
�Pj�5~���F��5��c�Z:t@�F):�q���2���_{���������=���j����k�w_yHx��>Q���jЅ2t	zm-Qs�e�~���a��v��Z��$<��:}|�,q���w��$]�׫w���"b/��<�f[5D<�-�ӛ�r5��YA����'F����e������[�ǰ6:~HI�zfj���2'"1���[r�1+%v�fW�z��=��l�ݮ�M�"�mFv��T���b{l��Uu�ӷ�%�)�A��zK����9m�ĥ��$Դ�Ywo���|@$:�s��cQ�<)W��Y�� �1� ť�t	�G���?;8��ǞBW8tx��ۗHUDQ���;O J�\�]S��̼�;z�Wb�� �31ə��<VYE���:ʨJF����]�پg��H�
�9��H��)/�5C��̸:a4CbGT
�"6H�8IMG	�2�ĸ-������a�c'�M6U�$]Y %�è	��9��y-@�
h�v/24'�B:��簳�U�_��\kc0z�U`����w�c�Z�1mo�2�ֆM���q�nA�ӂВU��0��>L>Lp@�&U3bF�^��q��2:Mrz��ez���ry\�؂N�� �E	.u�F�g1 �`P��Becy_7���d1VS�o_��}������[0�4�'��e�=�>��sr
��<{����eI�F��F��u;L:�Q����6�$V�HD�>N&�;'@�Ω�j����D՝�'��M��\op�Ӆ��䒙��������\��p_KG;#l��vV��
�~�$F�%���d��>�6��w�#
�b�!2:�^�U�'8-m�-����B�� ��������7���o@/ic���7��!pѧ�&u���l>�A��3��θZ	����H�T�+]�R�8���=��fzd s�Z���9#��`��<]cHJY�0��8^D��7@��S�OО�]���1�M�[`1%��
>�Ґ�b҃Co25=��̓�#���~Ms���q?}%���{���b�7`'qA[��$�C��^����#O��	�2�RU%��:�`����.w��jEgb��p^�{�Ȩ�dʆ�r8��D 
ܳ�dOa�Y��z���`�Ь��4�C@���žq00���&^Y4��JD[nr��rlr��I���=s�dINEq���,ށ��(ğ�0��F�t��Dl���yd_�e�G��K �  v�8��5�j�"g�c��ʩ45��JQ�J��l����uP��j%j�y���a-���W���>�����T`;�͉���`d�>�ͧ�!�)�ł���:����#T��7H]�!zNn�B9��\����Pfg���p��Ed��x�K�.�Y��x<���;<"��F'���W���T��9`"2���$X����i�׫&9��?h	/X��P�|��[��#y��U�0s5�D�0w�K��?n�� / >#F�_����{?��T����oM�|���׻~:���g8�v~�Q?��)�]��++py3���?�A:�5v�A�4uA����)-���=p_5d�A��*r.�ۖ�=��1�Ͷ�X��*���ĢU1;%���r���@��c]�*�3ߜ�'�$�=dk��F�r�(<�gm��ޣ��#�w�M�5��9<�e�gRŸ�kҟ����?���ri��      �      x������ � �      �     x�u�1n1Ek�)�D�{�m�n�a�K����7�v�H���.|�A9���	+ߍ�[�1�k���g�_jy��V�	�^��W�mv<,� k5�i0X�����.��TQ�TR7�T�T��\�a�Ԋ���3ҩj��Qѥ��V�E��nk�L��
J�@��W1�������-}�z���0�%Ҍ�����"OqW]3����0}
����'�K�����}��jK���V��ٔ)�$Ggf������P[M�ce�j�E���e۶/,��      �   =   x��4544106�M6�4�5�L��M27KҵLMI35HILN62�t�t��4��"�=... s�      �      x���Mj1���)rɒ�V.�E�]g#�L;�d`2z���AZ	�{�'I��X+D�25�L���������k[����H$�UA�)�4����j��]^�J&S̢�R�ɘ�s��3�RZ⩻so���>|�>�,�V
�Dm��*Lj��W�(�-��[�D�"`�
�>�\;"�D�y[o�#zk���@�#��2�L�Td�eV�;��[߾�v'�8�:�Rf��<p�`s'�9�Yto֖�k}_�q�Ͻov=</���o@��Q������{���*      �     x��X�NI}��@��R})�9���,(�Vy�'��ND�~k�*�<��#K��>�s�T��C1P]ʀUr%�ZN͕j�'�ۉ����[���n��s�y�i0�S�`Lu��$����m�5�q�*{��'��,dK|��E)v���`X�Ic�PBDr@�E�B�#s�X�n
�W5�Xb ΁��N�.�i����T���f"4�AkW�5�ެ�6;���_* g�y����M���p\��Pr�9�֦43Dbp.�N��8��ּW���z=]��q\P0U/�;��s1P$7�IOZMل�o�L��3�<mx<�5o�/?!A{T��`�b�@Y�.v
�u�O1{��U�.y|3]\�onH�
�л��n3�%%�dM��6��3����e�T2�v���z�wT�t
=�X�E��m�������s^o��d��+n��tsq��������?[H5B7-:SJ�8�6mW���xΗ�~��.>;&L:&���	Hqz�FR<%���hR!V����r�Wj���Q�MG�p+�6���D��\<ti⍥���־�V��~(.|�����o2��#cjXR��&k���|�b0���_���u�����yo���-�rњ�jE=;)5������4��*�o��~?�_n�=�?.A�'�>�]vP�}P����)��<mw��t3#R&�$�_����V�;m(�M/j�A��@�������R�_�m���(3~��4�eK>*X�DC1��E9�U5� ��P]ED�N1�=1���n<�m�ܦ�އs\�$���qe^��P�	Dʓ�A���\.x;��:O7��=S�*K�y|�<H\jl=9�:&=KK@HMD�S���<�4���ro1{�lD A��UOJ��BH��I<�,���N\��+��
���Ղ���1�Q~�УK�6-������`�I�W����l��Nnn��_�ϯw�z"k��d�X+ZIC�b��d�9��CG���Ѻ��%څ�B)�
��wJ:Cv�?&ZqYI�y�;���ox��剣�N���B���xԐ�5�Uɥ���f��O�K�")��C�3%��jБt��2��*�e۹�*��|��k�%����U@�{�D�"���wѭ'��C�������/c��-\�^�8t�Y��H@QO`��L
v8_s�|�UY:6��=��wp��ó(�J!�./tTm�FI�E��!gԱ�5}$/���|������xD��G� GCK4Kg��X,�ڂ=      �   �  x��\]�\7r}n����Ȫ"���!o6 ���l���B����g$�h���b�^��� �^�&�C�v�ʱTc��I�G�`mo1[���eʲ�}� �jhUs�©k�9�u��H�C�BAl�PYR����V]��Jc��ؒђC�EB�I��/�v Y�G�!'� �r�-$�q��s)��uN������BU�Pz�Rs�T�`6���>����:�q��\]ع%9$J?��x�9�A���?>��(tL�@������gl�R�%P'`�W�%i�cO�N���v}�R�K3�6����u�Ln�0�Qe�)t�t�yv�����ۛ���^�͗޿��o���_�g�돯>���o���_}��_�F!F^E(Dh�@��f ���`��r�u���9��u�;�H z�����H�0k��{���E,5�@;Y��i\1E|�DF`A�����W ��LkY`�q\�c0�A�v�݃:��� �"Z�k& W�z�@��dR<r:*��{�y�4<MqH�Pl��A4
*�ҁ%�Y���hxK�["�%O�~]8� �9�Y��HR��UX�
@h �;Z��GQ�!�����1�k�P;�4�"�ߵ�+cdJ(�����[~\6�컒🯾��?~�����߽�+���Ǎ��Uw�Ba� ,|��lKy�>f?�5[J+`�v���p��b.�چ�\���p5ߣ�o�!kY��.3�F$� �:�^��FF��]	��H�M�i`�k��"��cb\!~P��:Z2ȍc�t/͂�<�sh��0�E]�����Ԣ@����i���t�Pr��0���;��aE���䛘���4�3!/���F3�_`c��jV{�cO��BNc���EAH�*x�R��H�(��<%�a)�P2�'��V��#�U�"e����9���uF<99͍�S͸i�`F-�*����P�������jGySӭ�{��n��q�K�&t�r�%K�;s��������Ƴ��/��?d��ʆ���������(��Pca���DQ*���b����2�(�*`���)M��E�r�>DC]xK��ȉyRH?���+����4�b�)�1�;p�;���v	kr]hT-�CL���e���-w���9*��
"4��,z1D����%XV<�c��D^���4+U��D��v���5V��D�r��Q�A��Rv�BՋ��[�b��p<r���* pk��K-��s����"�J}&�8ʯo�f�&#�%���D<��������#�=5�ie}s�G+k�!X�R�D��#r���:t�k��Ո��E7�BS!��8��h�0��ҘB�[��8������
�K�BB*rBQ�9a�XH��0Vԃ}�>Pd���dM�E���8�f�@o��({Cd�p�̛��Zp���N�U-��8U�R
�.x��V���ZU�%^���׺C?rϽ��M� ��[h �fP?e�#ʵ�C�k��<�� `�3���*|.jH�ׅ��B���*��&5�B�H��1�[C�B$�ˌ��郋T�\p�$B���掳WU邺���۲����@�R9p�{����C_�0���kof���@2�`ma�A�ɢy�+���$��Od����"�&d}����8aV������P,��] ���VJj�Bu\يU��9E߮>�F�Y�t�s�]c&�B�g���	H(]���#ʮA������:��t��>�$�}l������<������hd�2�A+}�j�|Ž��ý��W���u��YrN0���&}�7S�s$�Ȍ���i�=a��E�=�6y�0I:�]�@`@U�i�2�~���㼦"�X�LdK�VoM�Qs@�,l0�(J�h��!Z����8�y�Q�Hվ�,%�x�7��#,��s����ebyES|�#!�>(��6��̾��-�½����qӄ���!�u�;��C;׸X��z��O����4 �s��
�o���=e��)�_;P�Byv�X��[�0ރ;;|2T����z�|����-�Ŀ��}$3��@�z��t�ufN����>�L�r�Ѳ+�8J�߯<�}��c�w�C�u</�����d�舧4
f���%�{����PAy�<&�3G��	~ƅ�fx�#�6LpC~��WL�h�=i/o�*�ym�q��$=-؃̼�@��K��F��1Ϣύ��/]`(Ӿ���j�2�bLR��t�����L�w�9�
'2	��D�T)��hGfX�C�'I}�(RN��H&��P'1ч�r��-DhK�-�9Y�����mB�;�]�Q�Q�=�!���Z�;d����Q{���;�ח���=���v�T�6(Z�nKA}T��+&lvH��� է��w|D�7�!yY���{�h�&d}�3[O��C*��w	�ۖȚB��74�.�X�y]@^���(�����<�B���f{Qs Ge�;���$�0����9 "��{W��,�]�ľ�ǔ�Nl��a�4 ���f����N�BSG���<ëG��nש}�5]�rHE��{ 9=����4s%�qBخ~y��f1�A�m:��{݉��, 9ȓ�-_��>�K�E2�Kv������?��@Y���s`�i�����P5��E6�Q�p�L���)��H����T$�߹qz�&���iM�_���ׯ���?����n��o��_���P��@
�	u�{}8�lk����_��푶QB�=�ۡ;��N�.i�H�g�(��
 eF^Tl������l3�f�x�+�R���~���������*@�)wՂ�<aɧ����
�F���I��6��ys�u�@�㦊_�o�����V*��⻝�j��
�+������?G�4���|�����D�#P�}��q,��nHO�D�O�������V��A�l�4ٓ��T��<R�O�}H;&��Zy��(�R�G�XX��E  ��+�/�˯\&���%.&:�r��p�2�{�S��X�oE���ׯN+H�����B�H�F�X�������#Gw@�t��O���~�(�����C02V��!s�ƙ��k#p�<�\ڞ��(4T���1�YM����E.+=XA��}��U )vZ�?�0����7�C�Qv��[{*Go�\y���f�<��P�����zЭ�SR�n9��^��
2r�Fjh� 幺@-���筯����;�}G���$�5l[�O{A��%�[�K�S۪S��p�V3mZ!&�,!�^���Y|9��+��w��0npɝJ�{�ܭ�'��8ܷ����Enha�{�>��6��EO�e"�=0(@��ׁ8Y[�S�����ڧ";C�lD� Î���X�V�����.��g��+���CM�d�!�[�_& iRąB�
uMwg؞�J�����FMC�W5N�O���~���s���eW����(uı�\U�Y�RH˘[0������`n��V��G��^�@�@ɣ�L���0C��1ǴSd<�t���ZE!{D�oO�\x���]�J�C-3�>y��~��O����8��t�@��~�:����ɪ�TOb�ߧ,��4�{/�	��zx�@�}zU-�w3;��|��_����拟~�ї����������/��o���U�>&�w�����c��@n���ҋgU������r:�~���2EOFa��E�G�*I�ȑQ��8�׊�������r���:k����Qe�����YSO:�W.D`佱_G�)��1�����gy�O��1�9���Kn�Ԯ������Yş*b}��i������7W������a��<����Ѭ����T�>,�o((H�3�����c��0`�~�5��x��F�@O�Z�o�^��w_)���U��_��W�}�՟�o�櫟���O�dܕU44�-̖��w�4�0�}�Zc���s��|�F��w	e���~�^����o?����&=�      �      x��ZI�Wr]'O�f������&e�&aD/����Tȱs`7u�C'�I�<2�P XP�m���(���?�W^�X�	Z
kl�R��޳1�u�0�F�|��.��JD���UtNM����Xi������*���Bw�s����ۺ���h3<۵��x�ґ�ƶ��mu�Ǜ�#��f�M[o�a<��G����O��f�S�w{������5��Zj+$��A�־0$_���:�+�`�
��Er�	Ӫ�c��͋�ҽx��M�X���HM9���`��ۑ�6[�5�j�w4<ی+��áNxU8w���{~3Lw��o]����{��|�{�p�}"�����͇V�$e��$���8��1W9�0(*�Z�KB`]��.���b�KZ��6�64�n{�;�a�d@��c7������͑V����c��fx�ˇ/��O���B��e�F�^�Y�A��(��P����y��RoV�8�*{"Ln�ٔ��ū���ir��˗óW�p�]��r~?�n���܅?.��1{ُT�-Q7�	i�YY=�+��Xu&��tWj��eP�KĆ���N�$s_��o/�����T��nk��N_Od�:8cdAЃ)g/z���R�2���;i��-  *e�mx���5�: ��׶jbX{6�ھ-i=�[�\��<F��|�rz�؏ï�� ���=���ڡۊ��� C���]���ʟp퓁s/�:pTM'��AF�S�"��T��n��8��GrQ(
�<�A��Hі����=F��@��^���N�ca�m��8����`��S�V���t�qA�Aπ{�1S~��"��M�o��[����_���0�����'�u�M����l��㧃���Au�`0/�V��LV���ާ$]M*�lkB����xƄ&t7!Hi�W�7��SvX�떴�J0ÿ���妶�aحhys��5d7C^5D�E����/�}����S|��qZ��DryZ����G���8.?��Tx:PQ2=6��M Z�Ӕt�Z�9~���+)����Uhے�PE�M�!���+:��а��(���@W��z�4��o����x��VĬ�5mNF�ތe�j7��[���=w9B�����W�SF�崻�!��:&?�mWK:�Ӛ��+@�k���tEk���/����26��q3�/A��v�<�v�� O;��l�G$3d���][�ؗø���~����Z�����
Y�"��٢"�"'�N���
�>�;Q+�����yF�K��+o��}	�������Q�m��l�[���{�u*�f7w7@�㞖���@����<�q�0����8���*(� �.J[�#f#���%ß*���Z�3{=RFgQblQ�"�E�3��oO���ӆ��p���(�<���;���;<;�ֻ�ĺq+��vxw�0���v7nQ� ��f~wZ�c�a��39�m��%�wx�h��~����ۼ�vj�o�����[�#���Y�a^�'�Wzp7ލɴHO�|��9���`nFXj]��*RG�d��y.���C�h'l�$bE��eW�B�ŕ��9�Sc�<��pn�/'��Q��%��T�!\Z������ޭFƃ �+�����&����߂��w�WM| 5����_��"�:�n1�c�M� UT��Z�0�ɩ@la���A�UPb��ƪ֫Y|��N��������Ph5r7�ĨP��t���B��s��x2h��!�������6�/��DX� ��R4'$��ށ3��ڌ�=�%���b{x�@CG�g2��1�L�xy�����u��p���:��Ո7����'au.��&3O���?������4��餀�`]�<fB�虙R�՜M�|(k-��ET������B°%:Nx�4^���Ex��#���[x�)�>X�L��K����9��K��L���A+#<)<�����V:Af>Py�D��w��y/�y���"�B���e�`|C�u`�	eV v�a����\�R.A)P+e?��J>KP7��R�5�g�`�+v-j�fQ�f���W�����_�8����?�|u�^�M�^�߯%�OA�@	���[�$g���v���L�#�d�V���NE��>���3������}`�����P<i�A3��N��ʂi8�Θ@h�6�5�ܶ%d�i/ JC
&�#h���h�	|g�32O�V���� �R
�{�J��>��Z���kT����x��=�Ԙw�\���	�f��Ic`�n�ܪ�'lh"h����f�!V' O���+o��(��j�jڥ���>�ֳM�Đ��d�b�`�-.�w��y&��F٬����ȽJ�I �5���&��2�`��=�:�R�\-6e4dC�Gh�X[��� �����	���Y	_ �,Ad�"����Lz4u�']�9����ҢA 3�Ʋ�VT_}�!VC~�2Ԩ|M`s��cњ��]�$W������o�a in�(�<;@�D~�kǙ��G��PA��K��|q'
�:�ιś���~�1P�'��\��u�ځ�)��E��9[��y�U�6!�|b���3! ��i�arKU�f������Om�\J2g�+=�3xv���RT5��Z�L���dF�鈉��Z�N� �*1ɬ�&,��}`����eB��֘���ˌ�)��\��!����T�\�zs��LĦ8ŦA�)������7��������P,�n���#�]S���c��Ȥ����yDA:�Wd�»�R��_iR�w��w��3E�EaS��� e% ��l3vUʹ�E�Yv��.|lP�m�G�	y:��`j����U8S�F�dĹ���Ւ2��2cR�&|��/5�ڦ��O�Y�=���m�����6�Ŭ�tF�.�mQ�
dp&(F�Y�^21��S � {Mh(̮�N�#k���Ƃ�y���vH�+m�hvF�*(�"t)�r���Ml���V]r�P@���A'��{&�`W0շkQ��,T:�$1�o��,Y�  do�q��Y�ژ�SɆ� nw�ޮu�Y&@{_��m�~\��亭3/���i������6�o@x�zU��]/���e��O�}�i5��!���a(Ps��X���#
�g����[�;�:7K�9H�ȚbM��ū�V�JL��F�4�/a�7�=Թ��Z��;~��V�m������������:���Dx��hl��A�rP:������(��Z��w���P��@�)\+���B����n����u]�N��u��}]�t�@�޴��Wt��^�;�ЛK���<{�A���Ŵ�h��a�G�Vʣ��k��C��/K��tP�܌�G57��Ж��xX̥�Φ�Lm�t� ����@h�&ܵz^�z��7�bx:)� �*Q$l9��S�������7��u>���_����]}�����@S�� �!9�<�$�)*@Z�DD3�lo]R�Qjn��ү�#�좰��8�7���Me���u���U�N���n��Pc�MJ�aZy�l��u3QÑ�l�c٠�����@���d��t�'޹��ᷛ�&As-�=��n�vxu~��ۦ����};qO�����n��c���:�O���H��My�k�\�|����;<��<��!�� �	�(��3�0ms*`d�H�9��Q�D�)(r�4J��xp躯x��|Վ�\^1lx�[E�֗���1����-?���8�JG���������q����-|
tDؾ������	 FV�A2ӂjĻ .(I�rV�\�ݩV�:~4��ߘ��1�P�_��;�k卼[�V����M���Y��{�9�$tp-��W:@�}��+IU/�<��`U��x'%f�5J�`oɢ/fT�#@�"�ϓ���1u�����td�f İ�O&}j���8n�������R����̈$	���6/R�#�☟R6�<�YPjG��z��%�����/��i�m�4���Q�M�*F?�D�G%h�j� |�9���1u���  �  �m(�y����k�9��ɭ�;.?W���9�Ù�]~>�����)���%HS^��_@y���|�/w������ZB����y�CBv�^�n���"#�����7J;��:��}�������VK�#|�e�z粐�oT�hP�}��4#{�W���S���D�)�}\s2�BT~`nס���=\��q?�LI\a�������d[O�U���B�3n'�ns�2������i�Z ����-�DO�$����')���j�W�}	���˛�?�_�z�?�UΘ.���q(+�\$�S�Z�)�lf�o���n@��'��X2!�e��\�ɀ�%Q�F2�W�{4ʁ��2Č�$�MKj)�1@��M�%��<��Y�5%���ڢ�@��\�N"� ]�Bmf��F9��p�7I��_jL�H@H��WY?s)�[�5��������,1B+����3�/
�َ)��H\.�:�@�3S��_ʁK��0�Z.��R��4~�I��D�3�z�ɃH
��b3����2)M�|)���Ux��`R�HM��l�*dg�A�x�ck㯥a�R!�tԺ$����|Kpbda�Ȕ�lc����<+ԸH�xK�B�5.t���Y�rW/�^�R.|MYt^��G�5Z��@P��X3�26�}R����i4�7�&�i�?��{{��_�@�)j      �      x���ɒ�q���O�PH�/}�HIF�b4RG^b%1 0����Y=C��
�^d6gT�,O����u�3L���ʻ�Tͳ+ӛ�k�Pr8ժC�K��S^�y�3(��:��F<5SK��(3|�K�/ukUs��L6v���n���~z{���?�d���^i�qo�����y>�wV��k�*��%m(��U^3$ߦ+Ŝ�Җ���q6��3�Ǩ��2��=��յ�Tr�;p3�l����+���Fp�ޛ{k���9'~����8Tk=���:��V�˜�i�����^�K�A4�uO���Y���q~����7r�|��"�k�/+y�_�]�b�Mg�w*���#�-��z�6�S1.>���N3��`��9[��Ԫ�i���6�ϧ�|�n~��7���S}3�7��l���C��j2]�h�d�H����]$QYm�Z5�L����^6�즍dsȕKX�0�N=�g<������%�Ώ�oo~�����yM���-���Rk���J�F���ki�Z�^M����IuS@���
�w����첧�x�����?=�ve�)I{��I���>MTNpK�T�ʎ�m��,�P�^gZ}en��A���T���Q�����s�T������~����O�I!u))̭���U�fHe҇+MUm�S�Xr۬�D�j�
�>�R���ֆXm^�c�!�w����~&����������]��^�sUk���)C���N�H��|1�I�Kh.�2�R�d�R�YX�1b�>e���7��|��M���|�E��H��v.���v�4�5�fO�UM�cT�5�`j�5z,]"���Y>�w��Ɍ�=<�r�Qz4]@���Y�&Q�%\ɐ�9��T�s3�ʷ��V&}<gҏTF�+k�QjPEGz������7+4�2�M�?��'�h�Z�	�>
��oo߽��7V�X��:���n:��ģ�4���kH�h��jl�o���L~/���*�D���e�K�:�w:�R��c=�+��LlKQ�@�.�ԜŦlz�m�U(7pq-�."4��ky�$�T����Ĥ)B}?��.j�Kh���)K�^�[l)�>�U�R��*���R�(:��T,�̲tif<����KG�z��i(�d9�����E��^lu�h+YZ@��ʂ�̾����]�ι��I�j
�r�f���m-"���~e�L��M��]/(_��q������&%�>���������:�����ݗ��8����ksG-v���Q/�� �j��1�у�k�1s5U'5��P�H����}��Es|k��ih��Ć��	C������D�9�m���$�����,0�W-9J��1�+��t�=�����w����J]���aӶ�Ҋ(��*5��(��^�������^H��>6��,�g���x[�(D{�����+�ZKUy�=4Lu�I�=�MY^b�m$��1��bh����u�����~�ᗏ����3I>#}�)�"�<����Q��#(��V7}�����V>��-���c��f��e�D�y�B6�"�;Έ���1DR6��G�fc�X���6��j�$m�p�AjQ������8�r�@.?����{9���R�gJǀ�V��ƤX�Z&ݝ���1���J9�7��k}(B�6�����p]��{�3��8��� %;���.�s��5��6[;b:�VU/�����CS&�
�8��������֧��\��R��4uM}�3W��%{$�`06C�N83BQ����G�hɥm�3�{�ӟ����N�M���4�xG((?�ܢ jFAL *��M� ��ޣ<;���'WJ�Hs���i��F	���}�`�k
��P2�ަ����W�^p.�աa��M���UiY��>�|ڷ��|��2���J���^�Q[�����E��n�Cu���0D#d�;�9
bl+��G|�u.=�;UE��A�D����^��HX�\��|����Eh#�jM�r:����,�U5K�{��$Ї��F�ش9[A�`|�2MtS��v�S�������|ڴ�H,=#�q7�C�N�#��X:��,HR��d3�I4��Lz��)C�Q*�剱���D�&.��{V�8vV[���Y*k�X�'X������f3�L��2���a����;���o�O:�g�fP�2�2m�j}����%����Y p��Ex�v�55�&K1�l��΂׃L2�8S5��l�jb�Y!|7km������Z�'$
��X�d�*#�b/1�������ޚ�b��1>���%�h*T�%3��o}�:o��A�]Ւa�����S���$��p�
o%�<���W�Q�+�4Co���M;ִ{!Z���C++��ƵF��}+y�����rը�C*�s� �,�5��J�H�݁���1�2�Qh	�m"�rG��C��.��<�����K�N]�_sF/1����
�����ki�Y�%��.�1�nљQ�oz��*A>�w֡��K
~�����A
��[>:��Z{�o��~�Ne*(1���k��\o+�U:&aa QYF��1EBK���vQ�$�q'V�#X+C�"��<˱L��.b�K�����>�:*�8T���6�w�N�Vc�͵j7���w�`�!Yٔ��[�(��V�^��p$o��A�b�y�hȂ��DchUG�7`�$rm6��3��U�P�d��"�o<�i�4T�n�D��7��:?�p{[J^Dd:Dd3���tԦ�B�D��kl?0��c@�eD5�<�`�I�4�r��,�+���x+ޝ�G�S�l�I�)J��������Ϊ�YZ�4�	t
غ<^+ª_ab�5�#4�DmE�k�?�Vf��5d���B�Ѷ���&d#����h:���0M�a���@��|��n��C&���*KU�����
4��G�(�>)��V�;Lk
ksL�P�c�P�n���y���&�l|�c�����������gBQيj�x�'jFҘΚ��'w[��R��3٢ɛ�t2նfZ��Uw�}ݜ�w�ַ�b��ʝ+��#X�3}W�$i$��Z�^�B�1���-��h�@�1��fA�ir�����7(�f�ޞ#����UƏ\���Bi�Ra�ͼ �7�����-��zp�J�t f������}���U�нc������Xc�>N�B�c%��B=�V,��h�{+�p�l����!Ʉ�h�����đ��ذ�� �Zu��
�;�o�r� ��{���
���g�nb��TrdzUS` zh6U���l�`���(;QR~:ُE���<�>k���zxG2e�kӂ�C�Ee�|���=S���[�H��Q�-�k��4(wiZgV���>��g���� G��
��@�0a^�q�tߋ]Ǘ��9��I����]���7\
�[��_cˀ�A���E3њ�K�������M��s��dK�2��\���^��ץ٭ �>��qz��z�T`�F�5N�B:)�q�M��2���O7\<��_S=�(��1���~n�B�y�⚨e~;�o��^;x�x�7�M��`��X�, �ⵀY���/��������bL;�B�(�G�'�m�*3�vb�����9x��.���+<"8 ��$�.4�Sx� e�!��1��nck8���B�#,�T�i�D�N���p�.ٓ�	n��3�	��zn�˅�u���u�m�Ǌ�ꖖ���[ZUf�T�ae7�!��@ĲY�_/{�u�bA+F9ʵd[����J�=�Y�ӥc�u� ��u a���OѸ#kl���Zd�'Њ��rn�5���@�-*4M�u(���?�1��o~?�}~����D�|~�%��x�s=�&��R������XP�@m���⅃!v�(gG�Vmi����dW��_�������O�şߖ=�:˞��`�HɉV��2�d"��-�^��\��$��� �.�צWԢz��4?��an��|?[.��Q����5X�V��%�������:��B�h�L�Y��W*m���q����ӣ:e�=�]I�� ����P�@�^l�]&�Άե,�������0�|�n�#:�Mǉ�Qv�2VR�F�6x���LI��"#�(~&� �  �\���M������u>_xl�a�1�_M6��A�%�(� K I�&�g�\$�#SB�|i�Y�A�<_J��X���ĻwĵVQ�xǪ��Sq��<�u����99DzW��מ{���r��ܯ��(ҁ�2�(�ޡ�!��"l�H�Tv�&n�	[>��y�!5Jh4 ���th��s�'��x��R!<+��ǡ������mn�&.��2���%���e��vƽ�Q������V��<��p�N[�W�YT� .�'�P'aҹ�58����Mľ8a�޴L����\�WR����iV'���"�d!�|÷ڒ��06oz@�vc��-�r:[�����s��r*`s���CL�m|W�t9���U��u5c�˓ǉ��P��e��D��Z��Y�b�sNL�����JV?
&1 �f���Y�X5��5f��mB��a\y��	�@��!D��n���
�F��o���G[����!PpFN#�#���:��b�f�h6�z� ��G��fC�s�nʾ�<@Qzf�D�C�l����յ�ʚbB˔<U��L�9V����KGT��rxm�`��{�>�Q����C�-6�لOH]T՚M�u9a0!�/���N�/D��S��q�;������`���e�	�(��^/�]����Iy'҃G��+��ųk�M{�=yjsL�W�k�c?��'�OO��R���6k����`|\��]@� 	Pb�Mʄ �����y�ED9`�"�V�p����1�Ԩs7�9á��	�����0��%�$~
�p��A���9-�h��4���}�n#**j3�u
�kˎ��'�X��e�C�[<3:�ڋ����� ���ȏ�$�׀�V�gW�dI�X{�<����"��KH2#r�������	�
ι��cZI
:d�l�{��2���(��A:�H�q���<�8�*g^�QP׏IcJ�A./�{�~/��<�uV�&�d�r��|�
�u�]R49&:xs%_�@��bz '��|}<+��Z��!O`�6C{���6k-q(�e�����Y��K.�J�Byꁥ�9?�<M�U̢�1����A!�u��ۋ��g�/0n�c��t�E,@�rg�Q��f�^lO>�{K��`G�N+㩪\ّT(4g�&<���E0C�9P}h��|�L|�aڰ}����ǋ�Rw(Xה��WA����u}����e��#����{p�P+F���e$Z q�B(���i��\^r��ȑ�½g���K;�?�8�O���*��d/Y�)����{����� p�Nw��}��[�`Q�{����ԍ{�*�������X��3�q/���|�%�ҋK���<�8��|�Y�m3I���^��)J���Ǳ1⣣���X۽�^��[�m-.A� �Ɏ��jxi�8��n3���������-�Ñ䩦����I�U�j�����a�� J���H�P�8O�_�v9����2�/8�!��)/4��<9����ǰJߋ����{6����SN~iy\\
+y�t��6��圿��ȭ̾��z|~tIAh�C�	�/���cnb�uZb�Y��ƒ����CA�MPz%�_��&�~ɜP������������fD�����y˴ ĥ��� �>�^����)����^���'ϥZ�F����+��_w��,6� �('lm�ҧ�ib*�x��+�C��i-ϔ�Kv��=P�,�5��D�A�� ��]c�W��#SHy*�X������^w��ʣG�%W̺W�94U [��z�A��>&S ���ʣ�hݕp�3�E��Av"v9آjb�����<5n���E��A�t+��r^]މ"/��~)��u��8^��Bm��@I��~AE�(�g��D��f�^>Ȏ����R3� j�W��d�Mhz�Av7N��"qTy$9U<�����2^���Bt�K����r��n�O����z�A��~��I{E�LE��$���Y��{�����X}o�=ef��P�c&���n�4cL��d}Xn����N���c����:��P.��`nW�}�5�~��q��Y�/sw����ށ<]��U�9S�I���<�?��u6�E�W+O�#"f2�?PmF����./�9 ��q"w>���wXa�ôFf�;�����,>п�tCD����􉕣�d7���;q�Ƒ�����8/���cKK�~b�4;�bqs/���<N�6')@���qk��"_������Ja/���4��)��^@,�)z[�(��7��`�z6�roC��8 �8�A846�9�����-��z4�/�y9.��dy�<aÆ�ù��8^z��1;�E$`8����!�R�֝u���|��r\)��r>0�-�l3G2�<����'g��s�ՠ���g�N�%9㋽�揰Y��<�xŋ{��a��b��2���M���6�Aŋx�!��5�l/c�񽂉+V��Z�^<�y��:�zy�E� �c���r����%$}���v%A���s��b��w�%���mE޷�͖�P�xUy�w!�+�5��ԥs��ן?�uBh�dꏓ�8�W�.��=����|��H��so��K�{M��2�)�~Q�)yҮ���l+����4^4 G�/����W�ܲTF��N�Xay�h݋����E|����)�!��A:fAl��e��H��k��ج��|i����+~�-ei�B@ޜl�Ir�W�X��QW0�K��^�j�GyoyF	㓣�G�gL{-�!�ڐP�����^�c��:Ic�F5�yW�<�o�fhn��͚{�=g�4#��E��qĽ�-�F�˦q��Z,�/mF��7v�]�WA�bQ��{����b<LO�3��isa_�H_�g�(V��F��	�e��VS�Nv���8k��ͯ�J�/��r��(Se�#��#��П��G}<ټ�ɯ�/B�뼊iI�z.y-b�ם6y{\3Ղ�r�h/���o����oP��R��v~�??�P�6��^��Ͳ|�;��M�_������ ��g�      �   
  x���MjD! ���@���3z��$QW�������f6���K�9,�h��`yV�&L,)<:R@���h.�m_��pI�7�r.U���dm�ڼ͚���_��t{O)�r��=�B;p�e;AXv��h�F�y�!�Ĩ�Sg6�p���ۨ���R�%��TVd�uJ�T�yg�%;��i�׵vMY@d��&m1�����,qVv���:�AGUp��u�҇_�t2�:'�8��: �O��u�xH�Yr{=����      �      x�̽�vcG�-8��Ci-�r��I�x���Ԓ��j�k�!� E(G�5�������.@�I�""��PJ$\Xs윽���ׂh~������$��JJN�ԭp�J:)doeJ���d�)z�Кɱ�ؤ�*ޥ���pz21�)��&|��d���]�ض�u�O��}ۦ��O���o����p�޽��k��ێ?߶��z��sڭ�����]�+qe���Q(3	��VJ�����G_s�����%LA�6��M��^��{+��|Ƭ�.S�QN5i���Azs%R(�焹$;�`�brSw"������	�*�?�����Y��u*iu{�9�_�vw��^����:���w�W���f��'>���p}خ��=~�L%&-��t|c�'�EjE��Tt�S�j�R�Tl6�/�E�u��,�r�tlX�bϥ��}�-�M�����n~l�i�6��"~�n�K�e�د��U�)6�U���`b����	/s��,z����]S���(�<�Dk�;�����m��}�����;�٪����+c�N�Z}y�~�՛�&ݦ���^�����v�˷ӷ�b���+�t��m�.n�V�vs���='n�]�F�}�x�[��o�Ӌq
��Izg�qV�ޗɬIY��!���52u��f<�v%�����7-��c=�Cp!�����P�l��W��=lޭ��e5��Z�n�OZ�6Y�	��A���BY�	_am�Z58��);�gZ�M�އ`�~h7��a��9�Gxn?��I��r�~���2�8�əު^w��퇲�x��䳍�I�9{*�(��5d�~������o~����_A,�E4ӂ�S�8�GƋ6)h�P�-�^��=�����L�Cpb�yRV�XRQ�ԫ��M�CC_�]{?k��K�m�{�^C��MZo��mS﮷�ͫ�?�\�D�Jo�t=�_<-m�n}��]�9̪��tBW���B���CRwx�n<2Sn�ټN�F������N�;�,�"u��:��k��ח��
���}��P��]ӽ�<:,��IjE���/�����X`�����N��W�L���y�������?�oV�@�P�`�\�]�q̇�/�/�F�7r��4��@�cOa�c���]UɘR�B��4��f�pPM=%U�TZj�������n�8ku�Eh�<��w�wk��a�wc�R[V�ϣ\��]eh����.�,Z�^um�KBc!\�S�R�Re�zN^��m`����a,�~}Q����κ�u�-u�10����SO��TK��,[n��r=S9`*F`f	���Dk`)���k�i׫�)�8��C��X���������i���?B'ir0��;�Um���	X%	� C�.,[z(��k��]�AC��&W}4&hD�h�����u�,��l�4L�9 ��$`��� j��,[��m5⼄a2��Bf�0�8�ZC�^}��
�}�:���f�����;�5@����:�.��C�M��B���P�M�vK8뇴�tD�s�H1�dL��p�O�hs�}��=���Y&���2�TDu*@Uԫo9��L8�Yl�����\��C�ֻ߯�Ӗv��W@��k�����om�������F��/\R���T��ch�"�]k���:L�w�L6�(!'h�^�;�M�<��v8ս��ټŏ/ �Y2�S���~���i.�Iv!��*���펕TS���o<.���L=>ߣ���r�v�s�p7��n?~DcK�? �}�ޭ�oh��8z��_^�����3�Ӿ���Zn8BGlV�6�K��.���7�H��N(<h���XE֮��	Dr/��)%c*r�x �Nv�7(S�{��uE�e�+TY��JE+�z�Z�v�F�d����HW!��#q{w��K>�$�_���.�Љ�V�|l��9`��R�r䓋Q'�h�����o��J)`A`�@��~"��ۻ��y������CZ��K@�*���q2�(E���uZH`��m�*�A�y<$�͓"���"|j��:��+ �ݥk9�HF ��(t�ΊH�l%6Z��P<�o�*'	:	zLK�qh�;pn M���mG����>�vi�vV��c�%选�\�q�! �f=*�cZ(��^a�u� }S�.�����Bg��pT�1�erVA��n��!���*�_au�G������'�1����L��J�����l�~�M�-��/��y�!��j  ��~��Z;���^����a(�5�nj�O
\݁�P>^�E��D�ŋ85�5q�q�3G_��ɐV��+��$-FN�9k!���|����ꮯ��� ��g�,5�`V8��M@���Y�Pp|�K���2�!6�Z:�`�AKg�>�~�i����)gi��V�
��ю�
!���
�bܸP� �)��&T87��8�
������k����팔�w����_�\��M�K0�24�`S!�?�PB 3n�
΄�f�TL�[��ޟ-*�8=K$���������mWH�ΐ/KM?Ee㤫M��\�� �*�I}�}Q�I�u���w)��x߭7�ֿ�AWa��v FlǈS�	�@O�v�i�6XU�H�4��jK����A�B#�Qz
�'@������y.�۶��ޮnR^�W�����%W���:]M�Ak�a;���f�5'+xٕ�Z��a��[27R� >%���y���8�`�7`���I��=�˙��n�^�7#�]�Jۧk�לށF��6��n��_o^Q�큜^�޵��[�i�j~���`��̛�?��pV��FU:�yCA�H�|��T��Qۅ��]�ĥ3����F�"Яh=Ez^�6�e�6K���'Gw.F����T!���s)��z�b��:�l���`1 �9�Ì<5l�C�Y_@W�D���1�|���@���z��wF[�	�]B4�e �nʩ��� D�^���u����U_��v���o�w��G��W�
x��x~��d�J#�s��*�E�D�T)g9X⅛R���A� Oܥ�a�B��L��r�{ٿY�K L�1�hv��1<	]�'�I��E2���*֊�흼���Ap������a�����0g���B$��9��F	�<]�6�6��M�Q�C@� �xR��1@�J�J����|���͚@�-C��M=�����ϩ).�HPb�,�,A3��k�i�H ���7U��z �ӥ�*T�\X�.!ݛ�]_rZb���DsZ�X h|�e�b���\T��Z6T�B�iI�^��c)�����E��Q�"���a*��_��!ۣw^�0Y�m"M�Zhht�����dC ��|�8kq��l����l}3�̹�����QZ:n�����t�J_cP�,D4�J6�P�zǋlВXLK�5�{�;�w&F�":x+�-�V7�`̤�b�r����Wף�� 3�I�gVP�$C��<d�+�ܐ�ќ'X�7�@��en�L���۰H"T�2jF\'��Tm�u�u�{U���������Μ�/�đB Zy�2:��]p�;zkQw�Pg�BlD��P$�� �IL:kmԹ�x��V{��?��yB���|�`����ȫp�`{�Z�J	g�ϲEε�T]�~x�"̏�y�=׭Þ�����y�-|ZV����8�.O0oعNH+�Q�*��.�O=f��IH:4-�ŃJH�}8i�\X��ȋ�:cQNj��X� �RǺ���r5�Ѻ�H¼� ��l4�q쑘���\�Տ�3䄏.
��>��y�H����]����$d�z�=�2D6j*��+a�"=%��U�@������6���� ��ڡ��ʶm� �Ag���Ŷ���q5孅89:���/-��"�'��š͈
8�B4Nl����H���ph8p��89��2VCw@@_���y�%y�:���i�:��~Q����f�vЧ��I]qDB�c0�2�{.�
���;�t\d�j��@�aW?n�v����3����7cG��1��@���2�%dZcfC��M��    "�R�ɴP?�!�a�����L������q�Y>�8�p���0��Yt�-��j�xU@aV6�T�����U+rQv�B�W����k��,1䫿���<z�>�Η ��!
�K&=�V/��'KT^u_b�Ǫh�<ݨPu��NO�h5 �}���?
ʕ�Ay���YO$9UE_9��[�*d0��l����>�#�kj����?
Ԍh 퍒^���Xj�E�M.K$RZhlU��1O-1��a�c�
��Ja���.����\���1�׃����S���@䆺v�GGP���$TkJ��TMY�!���(>k�L���M���vL�1%݃`c�@u�1�X���7&�ҵ7�ś��$�A�U��A٦+�`�T�$�{c�G�gT�k��d��L�χ���n�nV߼�%�H� H�Yu�Q��7� �5��y�`n��6���U�g'-pH	{a�P'��rRYF
9aT�%�B�v e���J/ڒ�4)�bam��1�,)1�L i� 8Wi��1��U�*�{ �V�i�e�-+�6ߔ|�v��7á�ӷ�h|�S���C�rX��]���{w���/�"�'T�V?�?�˫��j����#ن^3`����@}���I^����@F���"�x���Zx���Yhb��,�V�f��>�3BKhQZ�X�9,5�	���-}��K9�T�1�n�U�~M�M�I��Z"��D��)p�k�rj��2�R��9�ߋL8�����n��?���I�ۺ��m���m�N7؈j�8���}�?�^1�o�nF��I���m��*|�'gtO7w����=����(*庄�tJ �=	�I��8�l�Ѵǹ�SOҡä`�l�:�h���OK�9zF S�X��Ǆ/�O)w�YP�6fo�4�[v�3�0?��$	�p�MI�#��4@�x~Є���d�����r嶐����늠x'��"�+B�vڗ*u� ���h�̚�aN���*y",k��Ma�y�|�3��Az
��@*J^��wEK����HOb���M>8_�1�*?�p�?��$�ܶ�uXo[}Ќ�oH���&�����p�v뻩�w�^��p��a�xQ7�P͂�7�#�h���,��(k%8��v!��*0_���)�d�\�"٬R�j��'��A@_��0��$   ��X�j�]ˡ����2�XJ����*D�i?c�ֻ�h�H�ܵ���������7���x��1�o�%����m{l�}W���}[o����C�?捚�KԘjN�e&�	����j��k��,�U΃��F�pǐ�+@=��z'd9�=���܌t����ܶ7ؽ�a��e�y}3h�r��n��4cI2�.d1U�,��3�n��U�GA-aUpV=��|	ܣ: �rY�z����1cB_x-���@��9��y�t�w�n�~��� l���z>���L�2��/��=���B�nV��D��o���}��w�;�އ��y͸����z�+^���_oן>4k�g�����ݫ㯳��}��-��؆�{��7	<�b�k���')����eg��)t���.3H,��%I�M��㨶��G��	v̊�������@='OI���;V	�y[ Lk�B�'��e"�����hK�w�Y�8����A��L���)[��%9_1x�e�U?�w���6b�ǫ����v\h���l~9q�S#��Ǫ
�nՓ�
^���h�5,�Xh��"��#��D�e]`M<6@�����S���ڵ=��hIW_���<Mc������0ڳ�~�`'�|Ѻ���AD���4&"*�l�s���2Dn���`}n�#�!.��r����U��aq�T�(
,B� ��X�&����%a.� ܔ�����|�L�7��O~�o7@j�����(`�I����z�Zo+%���3"����Ss���@6v :F��Lc��?V�`YOP��y��f�����a���{� <�$��9*Xt�h�Ue�6�6��E���.j+��Q�IU:�������x0p��<�b|���x��#�gN�,<�3��0�=*,c;�~��^�T[�$`:'�b�Ƽ��(�$.x��-������z
���|���!q��vB+`�b2�ylD�̶T!-�,)$���3X A��{���#��zx���@�Bn���ɽ`Gá�%J �gN&(-o�l�*�L��M���V��Kx�	r�TK[J�0��oܰ����c�����t � �@�0N# ���t�����>م�O2}��Pv�j����4¨X`g�I�����9����3�	��e)i���<�,�[P�e{�G����A�C���Z��1[����y�o7�Ghf̩9cN�#�܋�	�#�cL&�e{�0�U�5"4"�:�π?���L��cK4۠9؀	μZ�h�f�O��^���ƛ�l�*
�Ņ�qپ�*�U�e^��)ѱAW��)[�!���ޯ[�݄����8��!C-�w5�(�Tf��6����e���lL����AdB��)��D�0�Ӳ����:���_�pw"_�7{�jw,���Yt	�����Lu#��|���QX��OF�ޮ/t��]�̞�^2L
���IvR˼pI��M��)#/i�S7з�K �f�\R/���>��aMTnSӼ_v̔���l��nB^6B�Ʌ��C
i�1��9P�U9��AF��_?8���R9��R�תs�B�˔R�8�&5��f� ���D�S�� =��s��z���@r{}}s����wϯd`��p�J��7F&��@����B�N�l�8� /VL>��杘��D��ц�-��<z�jN*�P&P6F�1�X�6iQ4���3Z4P�?:E��E���������-�?�QY�M�z�B�K�M�5Fch���PV9W#N�YH4�k%�M>�F���l��%�dS�yg��;���{qˏ=����S��]7 �}��VZye�mlIe`T�a�F͙�[]�N���:��d��ܬHE-H�J�^}w�q���'�=2�[��V�BY爤d��|�@ҕe�˪G-ѱ�tTB����R4�w��G��w�^��vi}��ܴ�C]]<��ɋ�S�7b���
pD�#���y�j`��WO��.�B���QeI�����*cvX}��_�i�����@��Ku��#�vb�^0�)x�"`8����\����pd<�yb�z��n,�Cwb�����}���ƛ��N�A����B� u�MJ<��ekU�(":�Y'�"&�kc�i����~=�x�����k����~^S�~ۦ�-��f�~�Y�a���(ĩ���5FƂ�.�\�Y,� a��s�	�Lc�gx�d�=	�?M~ڥ?���*�`�5�D0�Z<t�3kUu�E9�l|�)� ��Є���Z?�c"ޓ�|�`(:2��؋D���ݶ]ӫt�n�9���7 ��ͫ�])G�W=��سca�m��A��B����(���ܤY���T�d�i9�#���݁�L#���8|_`D��@�8*�O�������~[%��~r���G?�K�2h`U8=n�d�Q��ZXZ��l�΀e���9ē��U��1�)�����K'���
17�ڕ����q�926�4/T�X{�9Ɓ1CI��S�7�y��9}��RO����|��iJ-�q�ÈF���&gl�Y��Bm�x:l��:cc1��"�T-YD��j����*�E�-خo�/�p�3H ��^Q��r�]150g�����]��F�� �w�a���~�eԚ��@�)ٔ� �Py�F�� ޢ׻X�;�W/�B�Ř k�1ݳ�.�J��sХ\��� ��{���70X���y��.	��P��P 
�T�� ������/��^����.����'hy�"$�0�*L�C9��E��Z,�$��9�<��+051��1)z ��K�U�U������b�cq8˲X ���A�Y�N��Ê��N�    ��k�*5�ӥv�߆#WJH*�u;��b�wj�%/�B�<�XD�̋d�%�4Ɓ0)z}�Q�� Pй�'�X�FE��t�R	�]U��+��J���2���Dc����aU���˚T%�ؘj5B�mj�(��Q�g�dw}��f/���H�z���X���w/�HԦJ\dlE��O���VUK_
4b�
�Q��l��'��6�'��w�
n�<h��e���8�`�����mJ�2P̇1,
�~(� �-5���:�)���mXx�X����[(��M�Y��M�|��Y��I\x�&'�T�\TI�/5e"��aA��Ձ��Q3aH���h�H���o�$�x��_�����m}��s�Ct����լ~�e|��W=�w1��E;B4L�K-�m�� ����b�S���F�o��7��+C�E�XF�恀0T�J��XM�j�Iy~Rח'5�}
�K�����3������Qљ��9ƣף���S7���'��Cob�|G�����O�R�6�#<l�/��ss�TC��QKIH��DJPI�*ނ
U*7QC�#��~���(�)��e.V�f�A��rn�(?5��wet�zz�GI����4�$�	C���e��r��6��V&��
�ժ�W����/�j���	�X�UX\��d����*��5��2��`/�D�@ބ>�8&���hp�:�a�����}��1������v���K�3�Ψ��=����!�0�I�I����Aq��:����<�����z%*���mV;�D��>
�4�ϛ�����W3� 
�p���\W��&*���zF�S�{��6�z���Bg����<xb)i��(�k
��b�4���ïʕB!&�/��Qo^}\4�����n��8y��=�˩���C>FT���G�x��d����y+24��5��̒>�B%M������:'l=�r2W�\�30�0"Ҫ�I�Qi����q�w����{�ՐaĴ@���; ����1-�o��h�N�Q	\�1�͆�����ߩaJ<���0s�dф>L��#FKu�`�訅�ߪ,�xR��
f Tէ"J���t��w?���8�K`\z=���D���W�ud-˦��Hr&��o.u 
�1�����1�#jzV�0~�5�ee�[���ʂ�䪬��T��ѻ� j�>���C�,S���)����7f��%W Xh����l橑v���E���_�&�c��Aa
9ʩ(_�m��)�9
��,��	=�9r�aG���s��=����EXo�eޏ�+�jDf~PH��77/G폰��**���1� ��sb6����(��B�#�K	�@��T#d�jO�z겿~~A�9zuv4�Ln�4k+ N��4f�6�ƞ�2&g_�ȓ� ��YT�'��"/��?�u���x9�|P�V�IgyA��[=ˈ���z�ၖ �OS��O�%��U@5-1��	���1|w�h����*�	���!HL��IulDR���ڲ읱�	���8/E`2O��\��>���Of�+�F�������u�!4��Fv���E3Az��x���jy�8��*F6X��`n�#L|\�O#�w-7���<�fNlr���L�O��F~uR~�im;��m�u���r2�W*tPc��~�Ā��+�`<�\+θ��"�Z��?L�#���d�	���%��o$�=�0Y�h���4��^�&�+���/X��X��f�\���4ŵ�H<��?,ݱ�;������}�Z���J.�j�,�&�bvj��)�Ĵ�e��%8�l�d��D֝��� �W���h�?�b�o�:��0�Z.NJ��SMm�eꥒ$�,>լ�o0��4����,)�"��v��y�	��Hخ�Ϸ���8��*�<��h�%ԫ��+�q�es�#1�TTZ��H!����-K������Y�W��x��0��Ԍ�	-NyT�Q3�'(���,-���ml� �Q��$���d~���O�z$P>��W3�>^-#���b�r��j_Cf2�htp�$X��5o�V,�.�� �{A�#�`
�|`qݒ��M��g��^�<����YVE}Ѝ�R����(�Q�v��5S" V��UZ�����b������W������2��n�K����p�v��6�I>`���ʩ5�6)C9M0u�k�૳�7J@��-[>m���Ĭ.�7 3���/-���ϓ1�fý��� ���aM�`������S���/���X���=�e�Ja�P�����y|F&�Ks�3�����m(oK%uP���$+����mtMF�i�l(�<KpT��%p�MW��� ��XQY	�<�Y��'y7)��خ�[��	;����@,�	/�z}r���w���hX�E3��C�b���W6�!zLB��,�>(�a|NOY�� ᪲*41˖�2��	��]�{����o6�v�8�/��&\���W{gw	(8Y.�i�9 �*i�g�t�ò�V%��!6����P���`5F�e����X��zF��ls�T��~M�m\/<=}
Z�X�&�3<�L@8kn�Z)eMjNl���.�u'�Q��x��$T�v` ?�
�zw!v +lfh�/� �D�Ԟ�Fk���\�Jt�^��KE�mX����@j���^}��:#3�U�㷹�1��T���>��5�1�vt+ /L�	�82h���G�J�\�H�ѻPD���V�U�����υ�}��2y��K�1����1{F���l'�!����X��P��l��V�h�CLU�U�,�����@�y����=_0A=d� ��F��嘏ɚ5�M�Ha�$�ǲ���,E'rzF������Ē��_}�`+�����u���6��BU�z��#�� ��=�݋އd�eD�4�uX6�	�����BQa�$�؜��p�����*99��4�`(��������
,Z/c�rT ���f+�yg����{�����o�(X�ym�YX�����.��X�$]@#�dK&ҤZь�ZURT�l���{f��G.�UWF9=ӱD��"	O'SQ��i+N�
�Й��Y��}�{�@���,_�"BoLZ�Z��+�>P�X�u%����1^�;�Ul�q�D���FalX6J<	x���FYo}�ٯ{"]�E�+W?=�՝����%�Z�C�D�d�:��=�VI"1�u�h{��M�xo��8�I��hY��
Xʹ���X/	�1��9�
�.��}����;=���pIY �I�3P8����A����P�#���T����%?�9�ު �GŬ���D��X��#5�mղAG�3c
+�8Ƽ����ĢCV�V��-@�H���������eI��[���І`Z�VF�l|������Q��#E�F��@~LO��/g�H>S=��ey�]�eщ5=F(�f]����Դl�JmYs�u��wLc�i�9mDpVQ�ygr����l�O��P-�5�`X&B��������Ot�L*��5-,h�ˠ8/f*�<�0��Ӣ30�9M����!��]4�?�B���jc���LUv}a,��;��k�<�7Y.�J7z<o4�H��0E��liSս���^�]�Q��I<�'�Kl������\=�p��+�����.�&����P_�ӫy#�G��,�^3�,j�V�\(��[��<^��7,x�Xg�r`/�����)�l���L��+=5�#�:�5���=8v0Y4�J������e��.Y|bʬRQXф�/���<����E	a$ -��a�(�g�$%C}��h��ȴ��c֦�y���FhK�Y���L��Ck��yY4�4)�h `�8�xu�̍��Q˔��~�C�
�)Mީ5�}b���`W�c���p��wL��h�`�su����Ŷf�|G�@踴P��)1��`�]W,��qD�7����Nw�y-�d�����Οw�Yqbe�b3�j �*4ъ�^-��R�����Ȯ-�&��ۄ�/t���
ߵ]�/���	@�Ű(�,sM:�+:8�,����1����X���;X
���2    ��r���u�1���F�ي"#l0e
��,�aDS��IJ&��\��Ѓ_��h ��Pק �y�;n~ާ�a����,�X:�TCW�{�Ԍ��U	ȝ��<�ANkd�;���x&cG�v��G����� �gJ z��ԬKsy�*\9��ʰ4�"ݢ8W���9v��B�|�aG��/�w0�x�esOe�M�Z{���?|��3�*(	�vm�%����H�{pJ�l$U�y�a9$^�Nu�0O����]Ȋ��fA�<5��c��:wøC�9��R�@�ڲ�6V�@��"�� t��I�x�hu�C��`J�ȕ��t��QO�>xBY��a�`��XcK1
4cU���;ukK����WЧmzf4U/`Y'ր�����R�O	^����`C�YBLf뢀�3
��e��.��,3"�߭�L���CR���_J7%�%�G�+q�}�1.x�d&zP�Cb�8���j,�+���v�6=#;إ�0�����*�`� :SK�Ѳ�,\ ��3{dq4^�
Fo��ƫR}�)^=�������x��f��,�� }���T1-�$���"�N�gRN`�dW�T������â4E�0{g`���hƭ�V�j�-������[=K+�̳�P����� ?~ЎO�󚕈t>[�aƀqL�����B�g�GAew�Yi�%�;E�8�u
��_�X�ە��
g���fx����&Z���0�~��mu�/wz����a�����U�
�%Y=f�1}�Ӳo����B�e��:7��R�E5U�4�PdE��湯kPl�:-�aQ��m�dImN�(ʣ���;���;B-���U������������e�<>{Jx�R�"�(=�������!隡��Yx^���u`���2��uFDa�0Fd(vؓz�~Ju�^�~���tg"/,���K��l܄Q��� Ē�\6L+#��yf>R���^[O�j�{�W?��?���o��������}�óWJg�I��2:p"���Rey���$:+>b]|Zh9�h4A�t�^O4�EC���Kp��ဿ���X �
|i�tc^���"o������mm�Nx��Ig�L+^�Q�R� u���4������8B{
ߐ2P�Z<�KE��1�;a����4��e60f^G���đ��� CP���P?Ǫ���d����6�F�^I25���◭b�8��Y�����
m�}�N�&�?���0����M�_^�c%�
H���(�wFq9��ۄ(Ǡ-[Lg��Jj�0�ڂ7F%�Q��ƐK��������+;$��N�Q% �sP�Ӷh��XT&M�ٚ�IE��P���K0�5z+q1�7RϲP��"Y������a�2����7^w �:�g��@�.��}����a@-�Lt�da�c�@���&<
�L�g��X#z�8�n��r�F����@J�K�m<���n�&U�6�B���F8�Ddَ���yl�%��7�G�d%û�s��2�
 �&Y(i�h��$�FO)��%����3b�R�Xs��zV�����E�'O����L�Ǡ=Tx�\4Bлh@�x�ʋ8�ҋ��l�|L
G�z,�u�\����~���*%{�-�~�B�ϩv���H׷�{�`�{�Ao��=ֱ����)�� J��D��gK/4 v9�"xX�7�(~����4����Û���$�oƲ�e�U�� RL԰�]h�E�=M��%uU�Y(` �FeC~ڎ�v�9
�����S�G\J�ץT���Z�.3Q�e����n.�W �%�#�djN3����g��y�#N1�߻I�b�,�����cX\�b�0�c3R�'�����x&Ep��$��~g�z� ��#�9�LpɺЮ��p�B��@��*��	v�52�J|kWF�����2(��e�M���d]j'���Ʌ���$��:{�����V�E�h��躎qI�*qzu[f� �.p���J�-��O��#.��Y}�ne�B�=#ӷ��H6<�R�n12�N����U��уIr�X�BQ�W=���P�1!�Tr�S�\ ;֙` 5v��<���9�&��|�Ϻ�I�e#ɶF�K�Z�F��LQE?��`U������NAgl� ���P�&i�C]6�ID�3Vy�g�e��ڵM�J�|`4ݕm����!�A+��w����������P%��ׄ5�9�yJ
z��p��V�0aP�1���b�).�L�)���t3ș�ѫ`�`|e_��<�S��p��͑���X���a��(��ˌj�0ͨ��d+&T\RDP��f`���9/W��8F�`�Y�g�hB1�=��O�Kb�g*���\A�g("(��a�lrS:"23C����M�����p�c�b1P����d�Je)6�3����QШu^�z�%k� �8�B����Ef͒�2cZ ���ݤq�ӌ���_��M� t)����� 8��	 xx����L��6�*10�ev,y�K���ʘRb�5Y�`r5N&`bY��q7ֶ�cs�RIAN�g!��-�%{j���c��S^��4�2O�<z<�a�LvX��[N�Jڏ`)^��������y�©o�K�äe��:G:o���:�4��e��)�	���\�s��| �Tw�,۟��]�b4��,�m���j_Jc��@�m��ʃ�|%�eC �$9�Ŧ��Տ�b�tܠ�����w�a؄J��0��"%O�~l�� �`R���+�le����~ٺk�zc�	����BL�ٴP�,6R�9�"�]D����(j(�6.Ɯ�v ���,��I3��$؞:�5Udg��{�P�� �s<?��yXn�7��#�j94�tN6���Û�n�q� �Oun�x2�1"\f�7��XV3BȒ&Kg��L�2����;�o��#�a
��Vxe�g�tr�7g$xKf�=���< z�\ҡw�������Xj2t�����h`��VCl�(w��](S��sk�ӡ�:�fЏ3xi��|<�){8k�|J;�M�	���� xq��.j�hD5������-�Er��}����b�`j�����0x!B_�l;ܨ:�`�C�*2q���<����
�U����$�ߞ��֬i���s���r�s|n��bX�n�I9�͂Nެ����*�w�z����_X�p�N�Uj#�ĲܳaC��$~�ġ��/��R��d`"u=���giUo�=e�ٞrA��Hw�"22�^�H��殅��˅;�����T�Ԡ3Z,��=�J�O��x���j���b��c���,�W�_���_�Lwe܅�ˠ�v��U �Z�0���`	�[&�6��>�Y��e��l]kx�� Y��y��E�Z��J�ͣo݆������%�sD�!z�-84:��ѩ䱰0�
&-�p.[X����݌��W-�%[h�T�bW�C�)n�`7��_n���GRh�-x��U"y�`�T� ,��q�T��O�����uu��|��b��Ek���اGS��J9F��	 �t~�S��x`��׍����7 1����g�?�{3�T�<��ֶ���*�ש��]��]?��>���ϻ��?�FݵE�pMMw� 8�����y�0��wOJ���A��l�X��� WY�d�M�<):����-�c�q�֘�5���z�9ҕ9��d=nN���j���k�e�g�����m��j,��:���wk.߾�K׫����LÊ��n�ûN���Y���㍗U�#43�$���X#U�(S��w�B%nt��sۙZ�`�l�=���KU�S�Dฬ�9�cf�\�Q�h��������y�Иx���(�c�W�e8�����aC��6m�Z��<��%��.Y��wv�$�l�+�Uu8fE��,c�Xv�׼�ݺ�~�H"�F�$ywTj�-�V�l-� �qJ�����eᆈ���|��_��Kli��Լ�hFe���_}��Z.ǝzu*(��y��Q�ɡ������_���ۯ�_r|�iXC�_�ęA�__DJG؞d�4���    ��� ��C�ꤪ�R0��%M(�z&���� ½{��䫭��<���c�9+��!��޷M۳ǼX�gu��,��j�LJ��5g���X+�UY�lV��K���l�X���h���<���ۦ��jw�A����$�����W�m��2���+�RKQ`�8n,I�Gt;=��@��^U�[�nsk\H�-���QH��I'�c��?��H�je�^?����2�s:fj8v7-�����ӉP EW��[�gڙȈ�@ץag� � ,�>��FI/]-0*��]mz��,[IZ��0ƜB���
H<���fsfcyQ�m(μb�J�'�%&�.�?	�ݕcM>xp��p4���s�*�g{�xx��M�/��؅d7,u!�}�٭� �v[@��X�.��,,^��ϗ����*z��%��/\-��2��8c�xd�Q0��4GF����ܥ�5 6��qX���\b�;i�� XIN����o&y�\(�hs�5��X!�{9x���++�@�.]-xv` �3l�l�b�W��fx]U�RIf�"�	p,��gr8�T����OC�|�jA��
k��.�9�NT�I�
�����e(�_2(�}54��L��lǑ������l��t=�B�R�b�$�q1J��E�oV#GH�C�1`m�Y��5��7k�pr�c�/�f���(���п�o������,�ce��Z�"NL�UA�@ƥmIWրj��Cu`.��6E��X��<@��(��PA�{2X
��/^���a���aFUaFT��kt�!��F-A��$F�OX��d��G�=H.�[�$L�$P2۠�������Y0�e�I!D(o�?Mb�Y�,h<G��~A�V���Ш%����4ډ�z]6��E���d��Y�+&��I����^�s��ڳlJe(�9}ҽ�Z��-�F�i����_q��TN-���ب%�6װ�}�D�r"#H�{�*X\!-ܭ(�J<�!@���e(�*A���R�^/�[Uz��w	�0bD.v��XJ�nWH���l�11��z���mp�T���o�'��yl̢ͣ�l��g�ku�-�;-�T���wCĀ��f���}+��,?	?Z�p�xe�ru�A��42:Fg w��F��dUW�,�Ot����� VzH��bC�����89H�� 䇁w�n���@�3�Pz�0��!%B�Jb�ʥa+��$
`e��a�@�l���W�.H�X���A�s\6�������K�al�]��;P�K��cc*jlIh��Ĩ�EǶa�~�h�!++tw����;��.QmnBzwAfͲ��5u���
�a�X̚���i�k���&���%�]҇�ksG7{"�c	��ʀ��W%0�v�Ȱ�N��4:��X��)I(5��CY
�N�Ā^�S3s ����p�D��Y홄�膝J(�b��.~Q
�eg�P7B[R#'�V�����X4�S��)'���,8�^�(R���Y�-�=AN��̙k��^�e,ZR����C���Z�� ��ܱ�K��#f��s�a��YUd�j��&/�S���J��HvF 1� ($;a�мJ �������ެn�F�rگ�����eO���,����TE�f�=��'m�	pr����
т���?�w��R8�݀��P��^] �Y#�C˛������t����3ǿ�����z�<�y������Զ7��lM7����t��x�}�>�%����8�����o���ӯ8�՗?�O��M����%����c��u���߻��;��������i8��x����=�00?�Δ�uT����{<4]���;��|�Ǘ>|��o���c��y��[Yߜ�-��=^���)���q��u�qA�����/�$�6���Y�l�]h֛W+���K��7�!/����5��ߏJ[�����w����4eO���[}�Bm��?*E}l,���9������\b�S=��^˱i��qhG���M�����e����-ϫ�G�yw=&r{�n�I��߾~��K��v�����5��!�c�y��M����&qS�%�W�0���j��>����<:�
���>S�PAXX����R�-F5zل�3``�M"�r����+�� >�`���7��]!r��p���u��%�P}zT��]�5�t��=]VosP�� M2pY�eF�D&�FƐ��}ٌ`��(J���ā;��}`=Ϋ��{L`��z^�����`�)+�+�bG|�d�?�J��G���#V�)�9{��V5���}��{P�g�k���=����>��GrR�O��������L�,I�q�,�o��hi7�T�����o��e�X������>�X�G��,�T�?(�����_�Y|s�+|}�����?j��t�v�y59�y�������~�j7���(	��
uO���u��Y���?��?_��x���Y�" '�*�ǡϩ����v�J�)k�PM�TEL�\j�~�f��[���J��s�%�K^��_��]�����f�N�#~	&�Ӆ=di�fn��",�-[]�}���:m�����J�/@9�Y��R~�Z��ck��nNo���xk�y�p��;����ۍ9�8O���]��	^i6��=��ދ�er��Ϋ���b��XX�^:�����Sjj�O2�ǫ3���{ݬG9�ts:�����a&Y����ځ98;	��Ѳ��{������Uon.��>>A�,�4衎X\YL%(i�Z�E���Su����Sj��P�E������jV���I���aw>{�H����>\l��Z7���X��%��b�A� �q���L�v�X��CT'HQa�B�G��?l
��p3��o~kw7.��K9��ۯ�*P��	�0�M���}�����S����+_Q~�X\~u{{��g�y`��ӟ/��|x��@ =X{ �6>aY�'	�nJ-<<-����:>�;S,�S��ԁeD����Q����g�h��W�坎>�)N�>��?�,����7���-�2�VhfKfy��b��B�a�H�؃��+��[p際��M�� ����*��U^3�*,S�}V�Tn;�0M�u�,�f�c����&6�_��" �`.�Q�
_��'��������]bqJC��º@$�*J%��� �,yGg����|#�/�ą�0U�^�^,������;�Ss�e��Gc6M��G�
d�l��+l��4����(-K�	>�.5S�G�,�-�O��j��!�c��e$�u��e l��2V(���kݲ�r���1yՊ�:�_r	�b��i`�d&��n�c�J��ˆTI����t6�Б}����Z�����s�G�	 [m�c-#Q��V���EKՕd٦C���9��ubǲ�Z�"���"���{�SDp;T������Ɍ������0 �G��u*���������~����e�}�l	z�i�����'���Ͽ�޶�����v��'���fP��.�^_���/Ϳ�����O|����^tw�h�T޷뿵J����Ü��6������n��_.S�c�ٵL`YKf1xv�̊�P���Kf)�rMU+��6l����,�$��(�|���k/b��g����89�ޖ�יi��o7�����/m;����H�^����_�����L��(V������5&Ɔ����Aq�R�+Em�8#��<T�"l�e��~\.sG�^���_L����P��H��]���G=9mrk��5���0��*�nrE��q�򙝁C�y]����\�޶d6#��l�/�G���|+j�6Z4C>�����ЫZ$��Φ����H�<F���l����a�4f/ͪbڟ KR	$0���bЖ��懩��&��] @����G�-�td����awC�| ɂv���22G��#h�Y�%8�6�8�Ц8�l4;O\++��E��,�����b�V7�a(bꑸ�`����� ���.M�	��ɹҦ    `� p� �.]��J��`���噧^F̣2"kS:�U./��ǂh7�/��$B���Zh"E0�E�fQD�1�*���Hc����V�B-�N��J �\�ѭ
%��u!�I������K؞���g?>ˮ�KF*m��RCIf5�Ķ��I�(%�>-��m��m���}�ːlC��\&�#6�R�J��ʋX%a������S�V
�s�,�d��]e��h+<@<��/S�m�v�
3��b�V��#�A#�S�q������T��i�O�8eƩ`�Z7�YE�l+� ��	t��Es�E�d�{.&��7����֩Z�ZμY���_���3l��+�y۷[�~��fy�z�~��H�9}X5*��7��Eeg�gv}�X�(ͼXD��ʺE���Y�O�����w�Zz%ǵ�����h�<�-wɠ%ON��������)4u��J��PE�Ϳ���#2bo�.}�����x��~&D��������3�M���P�߶N�~*�=����g��I'��r��b�!*/��ku��j�K\MfA���*���.�nZn��e�a\E8Hy��Vp7e����V n�ڛ|����|ֶ�$s�ypa!���"�Z���)2�wf�Pˢ��g����
�7���pb֗�H��I��"�� R��C[��=�dB���[ޣ��y�ԕ�5�Vy� X�C��������B�2X�c�ٲ�T$e���[���x���C^F�������I)r%Z�-�ïXܕnn"#��P^N}B��gh��I?�^�L����pA?��C�@j���vf����p	�A`Օ�D�`�CP��N&�B`�_�������?���|ڴH�z�u����M�p�ys�r&-m{3ma^��#k%���6C �����?_|:M�����,�����e�� �c�2&PD̈�n��M�����6�z��WwR���]���Wb�H�v�k˼>�!)����E��^������s����XK������֎:�qZx���2�hQy�,=��;e��c��Y�K��n�6����0!��=Lk+Ê�
���]y+��n��=6�6(Im:S�����Ĩw1ݼ¨�C�|<��F(>�<d�S^�7��GF����UK�Vn�EA�p���W���l_�	�^������Umz��]�V뀼!���)�ϖ�8��ki;^�r�<�w6Ӛ�$ 5�]�s����y'�ū�8}�V^ޅ[�\W�lӄ�jQ�h>��w�5�rS�W9�@�-G��ywt�ƹ�����Q_�z�ʘ-8�.d,��@�5�#&"f	�ŉ1_��(= 6�Ҟ���0�*}�����D��~/`YEw�*�ě�5!�0�ʩG��9�CO� fZW���{���*����dV�j���Y �`�DqL_p���L��N��I��&=�(� k�T���敐�õ|Vv.#�Y� �w���з+�A�7^�A�n�r{f�,�5��"�{�2�d�m6�TR��$?���0��*.���AB%V��&�v5�ft�g=
B�% ���^¨K[v�"����u����5�k��'��vW��H7�Sy� �>��d�̨�Ҍ�!֡�v˕U/F;\I5j[όz��m-	��v�X�6y瘝�&e�+�`����:���.��_�p%�3�l�z�G�z�v}TX�m�-��̞G��Z�Ag��J�V����z�eS}.��W���E.��F_J�gN�יQ 6�&�?��S�����FA�O�0�3c� lU�B �\�";jt�Jfp�޲�:M��X��m�f@�T��8ż�6ur���'�	���Eԟ���s��ο[�j)�z�Ə�6���n�2�֒Cok	"Uťn���Co�`3
4:�<4R􄵢*��c\�ܷ�c�Y�`��������!�>��:._g�ՍaO��#��
���;T�s�N�̼�Ӧt�l����n�C�ի�ekq-T����=������	��������:����f@.��lY�w��.4���{	ؚ�Չ�f�K�ǵ��v�����o�̨����YrN�LHx"�Qy�������@v����C��.D��`�u�2�m�K��ٚ���J��jA"L��V�p��f��OP�ٜ���ܚ��K�pg��r�k��)[e�(�Cl��Yg�~+N���JU��y�����B3 O������#j��I�z*�ǃ�dV�Z�׬F0ɒ�%��y�^9q�?#8���.$��!�[�\�Y4���oE��j+��6=L�X� (��0C�E�˙��9��/��Gћ%B��X:9b%_��8[����ٲ|K��W��[��臄L:�E�k��-]����-�#ҥ�����&d^��՚��l��t[��<��k�qٽ�?��9��(`�Bv��p��!��C�N���l�m����$��C�$N{՗e>�	�/�۫d]_s+�ZdpN0`�}]&�2Wi���ܙ�w�N�����H\��va7+g��!`|�;s���r�ktKfͨ�ș�Iasx�桳y�;���*vѐ��u��W��H�ҸS�� w��+T�pXn�(��V���,0�\��КǸ3=�a�|�>;}��k�A�T�x�R����X!�}Mw���;[�t|k�AĈ��z�;��c �Z�*���9aR3hg���Iz�;�k>���*�����������j�|Hƴ����{w�U�.����,�=� �C��Vb �L�@b�g�+�,�S�wgF=� �cف����G(��:��J}
��9�����-��y�&S�Ͽل�]:ܾ�:��ҶJ���y��P�D����Z��,z�AnfN���[�=*Y��4\�/ɻ���y�A.�)|(c]A�$�jc:�]ی �=3���Z�rXga��2��9��gF=� Wl1;�)	�i�bn��3\IѮ���{=3�����"@My���Ղ�����uf�{��p��|��\gX�A���[f�<�`<��=u�(���&0���p�O�����a�x����]�0�L� ��E�VjVr4c�{܇�����0���<|�4'��Ҡ���e��A{��5�=���&��W��>�	mP1�o0bw������P(n4J�QHH�9�yx��+>�eo��х��n�^��M��x�|��]GY�L	��L����s��B�5����!�^�0d.J�vm�N���t᪜q�ךD�,�V��$Ĵ;���{�痀M���H�T���`&��zh� ��ZA�>��
><˩t]�kZ�F�t*�:lYuS
�$��JB�m�i�'�Qй:+����j��$�\��;���{#lU!Ѩ	��H#�|�T��yp����P>�\�f�5�,���6��#d��ܻ8j��f�`���z�8g��|��Y��5s!2�P�w1��9�駥K�m�&����z��{���d����9�U������x���^u��4��y'�T���;����e�k�Zn��s�K�ǘ��,��bɕ3i�28�ـ``�Ey�'�'
�)���d)�#X"�|���3�Y���iV�x��CD��S0�Q�;�/�'��9y�3��"T�: Ր�V|�v�0w�
�=Q�$��ˡ��ۛ6%��s �*���V^���OI�kԳ�"���̒�;�X.���,�ŰD��8�fU��-�q�d�L�Cͭ���]1�u�L��0t��p0��9嘦�����7�u�����,��-�!�)T)(�|�� !ؘ��D(�Z˲�_k��� iTm�.r�����GAKU��Э;�a�І@)ބ�x�f��xO����氪5mɡP`�.Qtu��玩��r?\ ���&%;���x!	Q:2�DTt�R(hQX/�1ICiDu�ڃ�Z6�� t�@Bj��?Ś�X��0)�8y�F<�����٩���P��L�PJ�+�ӓ�\�^Cb�,��T�e�0�m������s�0��!�|��.9U@� L�E�J��ڄٔp��$;#:�3�+:}�+��><�z0��?��1?��W��쀢gF?I�vA�(��m�����- ��צ֟L����mf�"��2�Z}�qs�     s��_��m�-�����}��t_��y�6_y�;����֑m�ͯId�3?���~6���A�&�(�!�RR�bF+	�{�����>�6�,].W�-�dO9z��:��r�3�vf�����u��9����=�`�(��8Ջ�R �1}S`�}��N��+�~�����Di����C�Gw��p���1/�ס�OH�˺;/��h^d�/��a�]����!�=���Q�o����ն�3����'�,(r#15�x�s�:W���,��3����h5}�:�<��%�pY�Pҙ��J��'�f�(��,�HQ�����{wF-t�*8��3���s_6z�;}1�&��7�Zt������j����B��6/�L m��mm8#���G���L��g1���+1��l�/������(F`�l����ɔ1�;D<_Zۼ�3�����z��W�=�8SK�7�b����~���q)�~C��e��B�����dgʶr)t�E\�y���,�d0�Y�>���ua#��.{p�v׬������B��̨+l
am#$Ǝ�n��,�9�C�ۙQV��&�R�n��������NQ�̨�*l�?��'!QY�d2�]NN�c*-z��6���J�*sw���λ��iw}�tfϣ6t{}0�Z�"rgt���R���v�˅��d�m�<2}���������}�^i�UOTزY�"}F�׍��K�ѳ]r[�[��
[�z�2=^��M����?Q?����<Qaӽh[�	�[����*���CO��
�>H�i��Qɷ�p��
g��f8 OT�v���Tm�Ɯb��y^	�̙5�U�V�}����*��%���5�4ڐ�����
[W[�%ڄ�i��g��Z���=]a���f���XǨ�A;�X]��±{x����������dp.ӌ��Pj�V~�,(<�I����+�>�>��":���F������j2���t��eP����w%����@/]-n�u[���2ό��i,�D[��(z�|��8������ж������޴��w�m�W�]��v�p�Pk�����S6[�IV4i3�N����i{㯉p����M�X��ݭgߓD٫���>�����5�4�&Va��|K�l��T^Fn-��U�ޓӜ�GWrh��(}�s��WȨ�eh�^�ܝ�@�ݮsZ���0���`o���`hM���.Q�P¿w�6}Ka��_������.O��\�1�ZN��S_��ٸ�����kP�s�U��r�|!����=a��2�Ћ,�<P	��!g'��>ַ�%a$�)��3�\A��璿3�W���H��s�fh�}w����RA-=[��I��hw9Ц<�y��ʷ���U��t��>+8t�tAṣ}%���a���0�A���,��)�ӹW�5�34{�)u_y\r����? 3�Untmo�}(�7�TjPY�^*�,�&������������1a}3�<��i���G�T7�aBsJb_nE�R�WBHP�4p�b�7z}�����ixf�� &CJ���Д���Q�ME��B���Bʊ��-���\�� �H�/1C�PK#�^O�L��3;��nY��xh�^�a��� L��?���r�.����5h��K��j��k1���'g��C���wb[D��AV���c~v���"T!���yzj 53uv��V8�$��b17E�N���fX��-̔ޜW@��䈿Eaj��ܕ���]�! �`�������jp��K�2�Jpƽ5`����d�U@��Q���M�ϵ��&���Ԋ�1?	���6�����5m=���qW @�O��v2�vh��n���;A(Җ�e��>��>
�)���e�]	^A�"O���Ζ=�-t�+�-���5�X	:J��̵��[��nU ���}���Uw�n��ݺXά1!w��	�1~=X�j�����8:���q��W�
L��Ĕ���jPt�=ݩ6]�ý3�a�{� M	ݯ�J�Z=}sH��V��-�"�Ɛ��Q��V�K���Sj�Q��d�FAX'��9hQe*��%���k���w�_�f��lE�Ra:���SSيi�NN�x�I`)9���2����g�Fq��a�A�4v�r�E&m�/�ǁ�H���wk
��Z[(���3kZ)�t�n_&.�f撁����e�Qu�n^��Ht����M�㺪P�1S�8ƌ�W2�8�q��Y�2m3��ba����.�if�]~�j���F鐅T����6|��5���c)�j�N���<�Sk�wM��^h��`C�t���V�v��gQ'�e��<w����¬��Y��m<�T�;C뫛�dّ5��N��"��x�,�C:������t��&����Ң ϡc�@�|�A�C�4���y˃�2#z������t�F�2�V9�/pD=�]�c��U��h�YT����}2��"��̸��e^71]�>��l�83����كN5|%1���vS��yǙl'F��􊮌�����w��F)mx��/a�><F�q�"GVS��l'�н<���z36�pf����X�>�����;bWԏo���:���bU��v��Ǒ��w�S����	�@�{b�SDuϮ��	��Rct D�Tj����A��DHT��Zt��F')@�E�N9X=\��15�r�@��e5���O��p�Mk���G(4L�.�v\;�U�	���&_�+������j��Xm�Pd ��Ԯ5t�\����G)@\���y�쀫*��;	˯pf�nD�!��1� � g��.�SU��Zϖ�IY�l'�kJ�k]�%����R�-�����њ&JfQpb:�)�l����ڼQ�gq���N���愎N��u����^�a�C�����H.K���KI��*%!Κ�� �!���7a|U�. �*�U����K�+B�-�xf�����-AWIj{��:CA9cWZ�Щ�~�������L��(Q���/aF�&�y�U���8���B�h���˄K�-�n�|x��g|�'r+��;V'T��^E���H�a���5���=�d�U�h�tK�Rk�m���H��]Z�� 2=Ϟh�t�A	ݯ�O��;_�7L@�kn�b�)�0ߛ�*�-���B�,3�R���	�U^�rP@Oq����ܳ����T�àZH�l-բ��7}i����=A����F�KsI���[�_���~�b5��XѴ+7ހm�����i�1r ���hyu��
;d��.4}GesB1�vb������_�-�[��)0�6�.�t�4�{��Wy�ڔ�t�+�t`�<��U�!7�����񱵦+-*���:��Q:�����L���^X�&`rU\��08�+�u�����+�O1�=,�&��!��nڴ��tf�������S��f�ʤ����Pa�< O3�	=�d�[!o $�6Ch�n�
+���)��"0
L��+�)&_
-qGSʱz�;�%��i���Ru�b�#��+qI�DܞFq�U��z3�ڛ�Є4��䇈��(��H�	@���N��ɞu���t@t�Gޥ���7�S�?1j]�_��������1�5��������W�_�Ո�N���f*1�(���`���Q���,%q�٤���$��$(S��������/��_���_a�o�,j�=�^�ڛ7�tU@��v�XB�Ǘw�}�����.{�(�s)�/$��6hGg��˵�d�%��HA�j7�s�qf�r�~�%�u��b2c˱�ymk��A}�P����~������x �(6�����v-�ⅲ�3���ME�����3#�_J=/�A?���-vo۵�k!��J��K�*)�9�D�8��J���V��0�ɉ&Kz�Nㄻ��{��J�)BwW��6���Ng֌�p��ls7U#�@��<�j�[p�-0g�V�<�"!`(�l�W�U�;%�åuM`nz+(] �����-X���95%�1b�� Ԋ^qla9�HZ9<2"v�[�$�ͬ���B��`���Ws��2��'xCW^�	!:b��_s9�C�Fo�Xԇ�`�P/	E�D�&�;��ΓM �  ���5��+u}O��0���<����Ldֶò' h��l�T�fܮ�| �M��h�|�]�~�l�{��ܒ\�B�3��s��M^��4����}I�:r��#��/�]Y����߀�c��*J�
��pi�^in�B7��Y��Cv�B\�19���vA���R?���.ߙ�X�7Pj]Ya'u�./�ax?���~��ܴ��C���.�N�MHZ�c�h�sM�S�~�n2���**_Z\�t s:���,�c�>K�.�<Fe̢#؈��n=���w�Y��j83*IIk����z��~�֬��e�!ѫm�/��z�TR�w����C��7/-�@ps[�@�wPMnB�:�F��ܒ��Xm�9�ד-p�z7��\������\�0�/8!7wfԃ-p��FWu0�=��ƪ�\�	d7%a=�����"@K�Bh�4�l��Kp/汪�e��Z���j3�n�s�i~�e9A���t�z;3�;h�[�R��D��:����[7���>��8��A�3��PW�l�J}\���;�T�n�I+;�&�Pآk����m߶txP�8Wv�BhP4Sj�u�0r	��Y���o��}T0��Ѐ����Jõ�h�͡�}�����J�N$�&s9�lc�~����ߥΗ�g�.��3���1B����[�mG�?�Wu�Mu0R��V�yL�C`ת$��3��n[��D��~�@1�
���2%�v��ӟ�
��3 �)t]���%a1ۇ����������*���xL	-O9����p����ѭ�4xQ�h�Y%^�iǸa�>2���e����PF�JW�i��x�9��M�Z��yh'�KW�_#׾5�Q��!���Z���Ckg
t?І�%��}�4*��g������j�[I�'������k*LgK�s~�w�'dԵ�K����ԩ�:�0+ѵN}��Ϸ�	�v�	m�� �a���f��$�)x������g�}ˎhE+��#��	�5q��.N�L�ԼnZ^�B+0&X&1���S���8�n.%��$t&���%�ϙJ�0zg�l���
gѶ�3��Of��Z�@�2�>�b�h�+xv��5�K�C�܇i�-p�&�%9�Q�3!�T��~1�st����[�t�l��>��k��m���o����Z����%��[�g� 'Ǹ�`�R'G��y���"�B/`?]	�U�Rm���I��ꉆ�`\�9������ӂf�]�B�q���<���5L�1f�e�n��K6�\�XC^�#�+yh/��paĩݭ���M�!��y�W��EE��֬I��=�;O4��٢�u��\�zrr�vw'܁��a���<m��q_9o�B�J�\�U�{�U���t���[y_$��n3S:���b��Oz�!/��[@�z>-�����
>�^�8=�7���?��O����1      �   �  x��W�n[�}&����5�z�� �Ay���^�Q�@���s��/c�c֕�"OU��ںP}����Nl�������9�<6�F3�M�17C��P�1��c�>n����8�N��J���b\m}l��YN��ˡ�vw������k6���|��_x޶�md˔�D�n2i@`��`��#��TJ�g�!�e�b�VM1���gy��C[��;���}]��c�l�k�Ҁ��h���+ѵ���Sk��I�ԛ�����m?\��Y�ߎ�O���{�������.�@߃n��(�Q�}m��4e���*'Y�����A�eO��SI�P�"�RN>��o����=��r~��~:�_�V� 4a�;Sin�V*�*^\e�]
u�":b�BF�bN�����	m��apy��ԟ�$�ew�_��?��Ǿ��1A%&�L�%�_��6�ܲaa�����ZP�]<��)��B��;�����40b}ұɜT]����q��>��5_7���W�����_v�nSq�;�I��&:��&����u,I��*�&_�N=���Ib(��]�oa}_CFZr)��؋P��P��=ナK됵�7�a1VU*Y��`H+�����Q�鼼�\���/���s�؋g�RQ�FI�0GO.��,8��������Q�Lh\�`F<�Z�x#?�����py ��ϰ��ݹk�_�e����cm9�=� R:����x�-'6��6���0e�l5��E���m�u5�����8���pTF[kC����ѯk�������r}x���w�
ڕ�8Q��56xSH�3�s1~%K4W�#,�8�M�P�|�t���i���|�~k�����]� FƐ`���bGZ��Қ:c�ǭ��
�AcؒaQ����'��j��_ۨ2����=���?7�o;ZC�m�$�'n2��0���`}�k;�R�R	��	���Hɖ2�~I��vǇ���&*j�F؁cz��
@�}���0ZX���#�Exp��d�i����C�S ���yۥ#������.��4��k�c��R�X���S�#�4$�7���.����.ϗw?H���MS7i�3�2;L[4��`7n:Y�͈h�bG��rb�,\�FL�.8�U7P\�U�D�"d�.�;�t��Y0�;�����ABr���иT����%��p1��L����E�T�@�v��P�\�5VP˯�q<=����ù����"8EL�h�CT�@4�>��D�E��֕�I� Y�:��)�|�!D� Ҙ���v���)ay���׻?��C�rnA��ȷрD#�vMBXݪ7�7'f%\�Q��e.���D�5Ĩ� l���i?��&�����'��k2�X��(3y	������Pd�[j6�V�fʳ��"�)��ٴ/�.�� wwO��jw���O2��O?ȡ�r��?��R�?���!�b���ՑC�4���;E�f���9ņ�y����~����T�QA�
>���>h��
����:hk\Β��}����<����臃-�/�|̞w��~�Yoo�>"���`o�6O�t�v0B��\m��jEp�(�S RX<r����6��V�=���t��"�.���6��:DO�Ǧ)1XlA�K6���@ɛ����~J����j��� H�R���E c��2� Z��n���9��4�Z�5���"(�ⷸ�����g��ug��`%oc��OჃX3�5w|�VĔ�P�J�BB��:/
N��k*�9����ئ翙Vz���/s?~�{]�e�,Hp��t��k�K:�a�9��+�j�0\S
nL����m�)�*�ه¸����5b�*���]1/�AW�Q��7�u�<&W���Rjs�4�x���iـk�͎r�'���Pň3~�qy���܆������@�[      �   Z   x��1� �N�j짚����� jb�R�����'��j���H$�"0[�6�� ��K>���m��9�q��0@h �I,���ʍh      �      x�͜Is�ږ���������8��ǣ�B  AT��V��%��[�yNZ�Τ�Q�;S���<��]��t��I�dH4�("�8�`h?@'Ĉ��#�=�Q����l�Ϟ�f�⥘��x�`#���i����Gv;�Z6^�NېR��M44k=��j.6�ܾLs��2�Q�B*�9P�����'ںK#�s�R���Z��Z�0�:�X�
k�r[�*(�_gA5�F�梵"��!֭�s�"���9�L�@�����H��A9��,��������E�5:j�8���k��Ÿ��=j���yn��*�����1y}l�e���T }ᒪ�K=e���� �$�֥��5ʵ���UZ���f�o���l����S������;Q:6�!���⭶�'�4�(�L�1�E�����?d���5���[{����	�����+UUF>��27�j���Gι��eȕK�ri�o�˦{��K��^��F�7,<Z{��$�0�X@A�lL��DL&!�0Q�̓_f�od�7���Ya����-1ҊV%�Uo��5kT��Z"f�:"v����]M\a�31Z;�<Ÿh�|T��v3�\�+�Vq�r��Y��m�J[����������"]����P�4$��m���e�G�Lf���n��	���������f�A����ܨ�'��W��^O��|O�ҘY�L^�_bʢ��㚽F�^���h�h�9��(L8�`�`h���8 x��1�M'��D���ӗ�Ua>��4��!����0�\}�� 02��I�n���\�@�BJ兌�H��B]j�g�\R�<E���y)S�
����A�-FG���$�V-i��~@Ĳ���l7�t��
ѵ��^�Ƌ��G�|������V��Gr��7Ľ!�Cr�D���*/�5�������S������`���İ(�*8[?́���z�@*~�"�̾����2�A�(!hFH� |"	$���x=E����0>��Ev��>{o/�~���e�}�(O����$�����sv���s��(/�_���k�q��+��>"*��AN��zՐm��A�̼uo�{������!� �C%��Pp��">I�'�E=��![��I�u'��ӡ�X���a�9O�A�/��O��'�S��w9n�9�����$���o.2��΅2��:r�W��ԙ�L�sAf����͜���8����i��[��G��1N��N;HͪtLR��R�>D-F�~A�I/Up�58�s��Zf����]��>��e�2OJ+�u��õ�=�QI�^~����
7W<'�@@���Z�^mD�R�5z���,�����;?p'�R	E
4.�v�E�(�Q���_Q�;�]Xd�7��}p��?�$�Sr��r���1��PM��._��H{KDO�3�Yh���O�_+��ֿ9I����%<Z{�C��O	ۙ��	A�X"��%��8�x��$q���6����j�]�}������a���Z�Qo!CjU;jo!S!������ K���YE�y$C/�=j>�?CF�cT��J�T�e��A -��3ȚA{ ���~d)�ЅH��j<]��-[*�SAo��^Ѝ��-D��VC�����FS7b�PF[i;_A���_:��N�Z���$DZ��ٞ��E�!0�z V�E?Z{�%`�.C�b���8&ߧh.�b�OS�^~b����퍲�P�O�����-������J�C�Ҳ� !4-$o�r)�]k�?X�=P�y0���p4=�����]{�>��-�|�!����U��W�Bn5)�<�&�5�+
���_�\l9H-�4.�8\��x��v��A�..��G�!H����`�L���r�0C��w~���8o,˕�#-H���:s�:�9���`O�@� �?Z{f��eR.f�'#" �\H��񓸎�1��u�2��������2E��T�W��sU��;��o�x�c
���dD����5m�r�2w���X��>3�5R%�q�K64����V����'�q�"	�i]� N�oa*8QY��Mk��I��;W�^}��,���j������*�0ſ ��׈o�G�Q��^�/�=�����S��2���O�S�0�#*;r3m�-�׿2E>`��#N�0�!�c�� ��~�T3<�P	�٧q����/�&���<1?�D8���Z<��rd�<�ش��biP.��l�g�>�4.U	$"��ǹ*�����JH2��
�����X�CVǎ>oJ#Lǎ���(*EkkK�63"������J�ɼ���$��t��N)�=�}���x��«\��{\_v�t&`�tTV<������F�Gk��q�B�ÃF!�"�3D1�|Hs���y1�CѼ��Y��6�h�~�&0嗮NvG��W����CS�veN��L�71�.j�����ܨ���v�i4՚�y(���8�d5�*�
��=4Q�^�W�*��S!'s�>Nk�(�x���39gx_�"��&8�}C�GU��'�Hybo�s>@M����p�SI�]<A]o^%4=n��P=v܍����̳1�I\ �	�!h�b)JH�J����^�������e-�|_���e�aG��F:����U1�@�p�\U�I��'/�R�,�[a�M<kt�*���"�>�\��`�+����e�>jA�Z���\�4����*-��;�]����=�ӣx���:揳�v�1X�ZlfZ�(�w�	�B���,�ZH��E۠������Gq��0�U��G����Җ���w����+P4��?Z{fb&���!(��)N �#��C
r=*|��a\Br7C��_z~�OQWA�j���W)�mH�b�F��JA|�>AU�g���]2��+�����g9�.�9X� ��S���T��A�k��z�ͨ��dz�z��4}�U�S���(�D$��B�O&���f��}��Н}��7t�K-qN�S�u�`wA���/^��)m̩u?�QѨ���<6�[��T
�)�h�,7��&xĲ�h� �
�$8�	o�i�ﳵ�2:����:r���5(�_�ڵ�/H�"ث�� l���葑n�.����U���te��sD_�Y���Kr�f���ۤ'�}+�[��Iyt�7�lm<]Y3��8	�#Y۵ͨ	m�3R��ꊸ����m�Li�}9ݓt�D��*�Q�}Z���tV�Βǭli������z�S�F��֞�����:���� t��D�3�aΏ�F�C�W�?����Ҧ�t˭�S�I"�s�@����cʝޜ�f��,g���w0���TZ��Z��K���<e�i�T.wA�� &�w9&'%D^,��1f�\��)dr0O�}Ј.�ٲg6����6�.��������#f,���Pϳv������V�,s�ڄtY����AiU?���B�����}#���?�����O�':G�D>�.8��c>��,30��l���*f"L�0V�ݨ-x�[�.��j�|u���A��3V�|q���Y��Fk���MŜѥ�Am�nWX������+�9���e���gZ�=�Iӊ��P��.]�������{<�.j+�[m�Ga�����F"h�oV��Hp6��k�1w��3�B���n%ձ��bH���7&w^����:�_��]�?Z{F!`D5&�7E�@|���0���/$�D8��e�n_l���~�F��G��@�VX��h�߾�hTYN<����LcE�|��[X�i��m0h .�9:^��?�yZ�}���ӰJf����L�6Y/8�\��R3e\���\����>1��ק�1f���L�a፼�i�m{\e�ӤOM%��m��G�=��g�e�F��3�b��/5����&	GQL�B�!�%!p�<9G�>������U�3[7�Y��7�?4�t��+Rj|��h�l�Z��	�*|۟"��b��ґs�*�Ѡ<���q��֔q��Q?�t�<�2� GX�p�&���]�o*�/���]���Θ/s#�6���'Z����ѣ��Z������D_���anhR��lئX*{=ħ*��6����    �p�N�P;3v�v!I?lQs�4�䣵�ЏI�A M����&)"}@��c�ǠW4~�]���S������O�uvx�d��2�G����3�k�E�c�ɢ���ۥs�d/�^Rʖ7L�Ϯ;��Зv����VZ���UN�+r�|����0���U�>��Z$�Y�,���L<Q��ĭ���j��m��~��d��L������8��MF�;�ky�X5�
��^Z�s�.��+lu9�[��f�8�`�9o��"X��bYD��h!!ɘ�⧞(��o����T�(0Is���
Lp���k�i����oώȢ5�q���b�2�Z���R�"��$x{H�l��Q�n��Q+0m����H�zi�Chc8��LC�[2�����_y�t��s}_`�A#~���*?+�~W�@:�]�.�o�rJ9��b7v|	���*�8޴�ڣ���O/u�jw3�ż\G|�����u�[tW�zT�j!�QD�	��I����9��=�QV�/ì��J��a��M���@����IƗ�
�<��J����`�6�y���B��움�ꢙ���%͢+^��?vJ�f��r-����ʨ�r�[�"�2T
�"-!�E��MD�I�V/�eT�Q��7m:�]��mo���^0�	�H����� {[�?o�F���Ymtz�n+�d��{Y���nJ���=��� a ��e���%|�'r� "��O_�2K�@jN����p$�������J7���~�}��Z���PYG�[��0]U{�j��n�v]�WZ�ԑ^�Sl]�m�����𖃞I���c�'�BU��aXGa�Wy�j~�(qRE�L��Q��[��*X�N\�����h�'�����q�W��'���E�ǃ#��Ŭ�j�F9�K��[{�H! �<Ńs��9�݌)qɄ1#p�I<v�	@�����qՒ�~�Ugah�P��u/P�4j!��]��e�q�x��� �5E�oF�Z5/35��U-۴�M]U��Y(-Cؓ���N�]gG��6-�ͺY��� �jXԧ��(�>��wk���. ����nm�F�o��*�R���in���^���4�p���� O�yh�
���'��l���ޣ��kw���x�X'pL~7��� �܇(�B	��Xn֫C����Μ(������|�^g/�o�_�J?NV&[m��z��2j;��JU����rܰ0�sT��'9KsV�M�@��Z� ��&T��u��m�n���!��Z3�߂�jܼ���v�X�2�SNmn���Ĵ׋�:h�S�[�=�7d��$D��j�2�33��#�*᝔����f9	��R�X�KN����3��Ͻ�I�e�[{�c!�I_ P�1�D�%��JX�J���M����"�l�/ʮ!p�o��3�����]~�
��V���V�})U���Ee���j&(˹E:��ܸ�Գ�³�)�Sw��	�(�P����V *�J���~O������zxP��1���t�5�Ce!�K8Û��_N��ns���nt����4�Za?�'A�__1�^^��X3mV��v~�����f�9Kt��#�A9l9�h홥p�����ék\ N*�Q�4���W��hd�ʮ�'���]�?��O�6��N�]#��6�h�T�X��q�j���vg)�������4�����K�H�t󗵚A����c��j�L�Sv��jG������g���ߑ����/�����V�(q�li���*F����L��O�nzhe��	�^X�����3u����tB�I��Vkijo^.�*%t�k�t��aB��#�>��bSADa}`垺�;[Ug�G��Q����ߪ�7[����ڤֺ�}GX�f���#bX����{�9�P�<2}1F<��-�+��_���<Ee�Es+��"�>"�Vƪ���Q/��=�_}��s��k4� es�}�2xBQ�u`s4Q��v*�[L'Y�򙭝�+�Ά���Y.��������T0}��#��Y��h���]���[�У��q!I	<����C�-�
INpF��'|L֩���O���/�����g�,��t8(���T�&`w�Z�E�>CUڴZ��V�R���W���ΩJQ�v �1�U�-�nW�R�n��H�k��_h��M{�6��g$?w��pn�O"��e���L�,'��a+*y�'�8ȝӹ�ꠄ����w�ё&�wJ��4^��YVi��=:�W6vf�)�@��=
�ڳ �4�Q@,KTaDd��󹄌�$��q|8d����������:����|g�h-�n��7V-xwJ�iƄ�_ø,�/.ڹB������g�f8�r]�"�f��e��۝��K��@���Xm�-�'>��s#��t쎖;w��w���I�>vy,)" �_�&��pn��.�F�ٳFoοjl�gK�ͨW��������;���`q�yP��ݶ�k�a$	Cq�'$d�K$���sE��i���A�uW�i�����uԗ����R��%�?��`�z��ϱSƲ�7��ǧ�+/�[���C�ץ�W75.蔖�.�奪)`�=��x#ܒ��<A�2\�V���"]=iU�[¬s�i�sx���afߨ�J����l{���X��/���>�sy�;�f�y]�
QA�Wvz:���Q?F���֞C� a)��*��@�9�Hxޏ&�����0U���8��n�ǥ�ߧ~�9�l�R/jk4_
ݖ��'���p<?�<���zQnh����d��A���Ny�Ϊ�%P�u�]JSo�BD\}Q�h��8g\E�VpgAV69���ړ���ai��J��oj�\GM�ny����p�K�믔�<t�K=�Ohѐ沕n8A�)���t=�j)�2��%�y��L	,�4Ot ɟ����(aR�i�e��~
O=�~�G/f���`���TiH��w
������N�T�vK�91D��9�/�2U��n�����N�>>�˻Z�[� ���<���b����贈smU�)OƋ��i�it%��aV��M3�H������S(�{�nK���F��QL�˄����Z�j%eZһ�< �jX�V�ў�5:7v{"���kψLxA���<B��h�`)�݈$�O���S�J
�oh=�����<<�|	x���>�u��Q?���=[C�vQ1�� �H�c�����j���*�]�<첽ҭ�J:� Ad��H-��d}�c�9�\�.3�͂�*�u�$a;���&���j�����>��w�D�B�<�d����_9$�^])����˦m���r���g��,:�q_>�,�ȓ�F~�Q�ڳ��w{;��o��$!�D ��#�$,��O��4��E,��_��O��_���q�i�H|у�y5��`g��o6���D�@[��oy�[jpXo"^�Z�����ͮ{J$u
5��.׫dړz�\�K���YyX��(n<����0��A?8K�lGi���̻*72n���h�~��T)*<��0�ƧRW��0���j9�Fix�1���i��B�7��G�c���n֞���#*L&A��
~�b�c����~�ǅ���0;�/���#}(=�J��虯 �[�/��\�clܷf�ڴ&�7�Rn�Y��sg���7��-U^n���u���������B%A����R�F��׭����%��g��nIb>������V�1�5�yZ/{C~r<�F~�
w�ޝ�|�jc(�CF��-u�\-�~���T�1��+�׏�~2��r�R.0��_h�F1�֞�&� #�'i�
�~NJ�i>��
�z{Ц��_��L��_�ຑ�����T�ר�m���歷��\����Ԡ�p�)s4j5�6M�jnt(��)��)�&�L5)-�Է*�=���z/MY�<�\)\MP�����T&��)��O)/Q�}���ɡ��t���^�����_��{��v]o�E왬N�Up�i� ͣl��֞1����Hs�uZJ �(��=��4a���A�2��?=��t�kŮ�e��]/������k�1*s�9x���P �  �X_�( 3�<K�w�E5���T��|��k�g1�4H�!����`43+ra�A^�Ueڞ�O��N�4�v���e�7Fz!q��#o1jբx��s�ٚ�Nc4+����tO��W�y�8�iN��<�&"wS-���,��a&$���t@�n��铄_�?J�׶���ʛ�_�/�SQ���0��P�!�����t�A�K��5��ڊ~d�2,֩e�ӵ-o��|�}a��52����:,�v��n���������ۤ�M%(S}�wU�ö��{�z<q��`潉�Y9Mf1#	��we��˪Qo�m�|z�zU.+�߱�x�f�uʽ*���ǃJĲ��{Mt�2s8G&�	c�Qo��z�֞N`�p�&��&P/�j�,�@��h�<��c���}����+�o֥�/�	�]��oûԪk� g�
PyT8k�7W�<�SG�T��o�����n(���ݕ4����|�J�.��2�b�#\�{��Ӝ�Ղ�!"�]zr ̺���+�R����36��O#dw��n��'[�˅�N.۰�:ry;�2������\H�=N�C����a�rQ �G��f��=Gd̄<N�����	>�x"იG,�!�d�i��x�U�n�V9���ԯ��F�~?���rwwHjrw��ϗ�}g���iQ(�M��~�W�m��ۮ.ݐ�Z��e ���n^��q�+�P%URf�k�e���d���9�Ҕn�Ee�k��P<��)(#g�a���5_���,3�'p��|��F��U��8���a1R�)����~�Rr�_%��Y�_Z��Y`D?Z{ƴ�]��eq�]�!x3f#0PI7��<��~��p������k�^���(��.�Ÿn輫.ݷ�!�����}2Nfc��e٥mWfm�c�Q�[�rMQ��`���u��n,
|�]�ʨu�s�~�&�SR�9k7tOV��m��eC�n�h�!}������&	�/Y����?�F��\����!������)��������?��>?E�bW�}����=�$��S溹���q�[֨�18�"(. ��!�����/pT��6�N6ݼ]���?����(w�������k?���T6�T
s���Q/�Swnw�dw��Z���B��n"��6�-��������n��˿'�3�Qb$�>+��d�e�QN 3y��.�h�G��T,M���>���p?`����}�hb�>��b�����t���0���L�^��>��a�b��Ň×:&8$��!}���߯�������      �   X   x�=˱� К��0�%������/׀c�U��My�6����f�$KMH�zQX�;��u�s/]9�7?�Z*���q�7�o     