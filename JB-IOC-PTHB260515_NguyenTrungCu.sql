CREATE TABLE Students
(
    student_id    VARCHAR(10) PRIMARY KEY,
    student_name  VARCHAR(100) NOT NULL,
    email         VARCHAR(100) UNIQUE,
    phone         VARCHAR(15),
    date_of_birth DATE
);

CREATE TABLE Courses
(
    course_id         VARCHAR(10) PRIMARY KEY,
    course_name       VARCHAR(100) NOT NULL,
    category          VARCHAR(50),
    course_fee        NUMERIC(12, 2) CHECK (course_fee >= 0),
    number_of_student INT DEFAULT 0
);


CREATE TABLE Enrollments
(
    enrollment_id  VARCHAR(10) PRIMARY KEY,
    student_id     VARCHAR(10) REFERENCES Students (student_id),
    course_id      VARCHAR(10) REFERENCES Courses (course_id),
    subscribe_date DATE DEFAULT CURRENT_DATE,
    enroll_status  VARCHAR(50)
);

CREATE TABLE Payments
(
    payment_id     VARCHAR(10) PRIMARY KEY,
    enrollment_id  VARCHAR(10) REFERENCES Enrollments (enrollment_id),
    payment_method VARCHAR(50),
    payment_date   DATE,
    amount         NUMERIC(12, 2) CHECK ( amount >= 0 )
);

INSERT INTO Students (student_id, student_name, email, phone, date_of_birth)
VALUES ('S001', 'Nguyen Van An', 'an.n@example.com', '0981234567', '1999-10-11'),
       ('S002', 'Tran Thi Binh', 'binh.t@example.com', '0902345678', '1992-01-02'),
       ('S003', 'Le Minh Chau', 'chau.l@example.com', '0913456789', '2001-11-02'),
       ('S004', 'Pham Quoc Dat', 'dat.p@example.com', '0984567890', '1998-02-11'),
       ('S005', 'Vo Thanh Em', 'em.v@example.com', '0935678901', '1998-03-02');

INSERT INTO Courses(course_id, course_name, category, course_fee)
VALUES ('C001', 'Python Basic', 'Lập trình', 1200000),
       ('C002', 'Digital Mkt', 'Marketing', 850000),
       ('C003', 'DATA Analysis', 'Phân tích dữ liệu', 1500000),
       ('C004', 'UI/UX Design', 'Thiết kế', 1000000),
       ('C005', 'Advanced Java', 'Lập trình', 1800000);

INSERT INTO Enrollments(enrollment_id, student_id, course_id, subscribe_date, enroll_status)
VALUES ('EN001', 'S001', 'C001', '2025-06-01', 'Đang học'),
       ('EN002', 'S002', 'C001', '2025-06-02', 'Hoàn thành'),
       ('EN003', 'S003', 'C001', '2025-06-03', 'Hoàn thành'),
       ('EN004', 'S004', 'C002', '2025-06-04', 'Đã Huỷ'),
       ('EN005', 'S005', 'C003', '2025-06-05', 'Đang học');

INSERT INTO Payments(payment_id, enrollment_id, payment_method, payment_date, amount)
VALUES ('PA001', 'EN001', 'Credit Card', '2025-06-01', 1200000),
       ('PA002', 'EN002', 'E-Wallet', '2025-06-02', 1200000),
       ('PA003', 'EN003', 'Bank Transfer', '2025-06-04', 1200000),
       ('PA004', 'EN004', 'Credit Card', '2025-06-05', 850000);

-- IV. Thao tác nghiệp vụ
-- 1. Cập nhật học phí:
UPDATE Courses
SET course_fee = 0.8 * course_fee
WHERE category = 'Lập trình';

--   2. Hủy đăng ký học:
-- Khi xóa toàn bộ khóa học và dữ liệu ghi danh của học viên này không theo thứ tự chuẩn sẽ bị hệ thống báo lỗi
-- do ràng buộc FK giữa các bảng. Cụ thể:
-- Bảng Enrollments có FK là student_id
-- Bảng Payments có FK là enrollment_id
-- Vậy nên để xóa bản ghi mà không bị lỗi cần phải xóa bản ghi theo thứ tự sau:
-- Xóa trong bảng Payments -> Enrollments -> Students

DELETE
FROM Payments
WHERE enrollment_id IN (SELECT enrollment_id
                        FROM Enrollments
                        WHERE student_id = 'S001');

DELETE
FROM Enrollments
WHERE student_id = 'S001';

DELETE
FROM Students
WHERE student_id = 'S001';

-- 3. Báo cáo danh sách đã thanh toán:
SELECT e.course_id  "mã ĐK",
       student_name "tên học viên",
       course_name  "tên khóa học",
       payment_date "ngày thanh toán",
       amount       "số tiền"
FROM Students s
         JOIN Enrollments e ON e.student_id = s.student_id
         JOIN Courses c ON c.course_id = e.course_id
         JOIN Payments p ON p.enrollment_id = e.enrollment_id
ORDER BY payment_date DESC;

-- 4. Tìm kiếm học viên quên thông tin:
SELECT student_id "mã HV", student_name "họ tên", phone "số điện thoại"
FROM Students
WHERE phone LIKE '098%'
  AND date_of_birth BETWEEN '1998-01-01' AND '1998-12-31';

-- 5. Hiển thị danh sách lên Web (Phân trang):
SELECT course_id "mã KH", course_name "tên KH", course_fee "học phí"
FROM Courses
LIMIT 2 OFFSET 2;

-- V. Báo cáo & phân tích nghiệp vụ
--   1. Xuất biên lai tổng hợp:
SELECT s.student_id "mã HV",
       student_name "họ tên",
       course_name  "tên khóa học",
       amount       "số tiền thanh toán"
FROM Students s
         RIGHT JOIN Enrollments e ON e.student_id = s.student_id
         LEFT JOIN Courses c ON c.course_id = e.course_id
         LEFT JOIN Payments p ON p.enrollment_id = e.enrollment_id;

--   2. Tính KPI & Khóa học "Best-seller":
SELECT c.course_id            "mã KH",
       c.course_name          "tên KH",
       COUNT(e.enrollment_id) "tổng số lượt đăng ký",
       SUM(amount)            "tổng doanh thu"
FROM Enrollments e
         LEFT JOIN Courses c ON c.course_id = e.course_id
         LEFT JOIN Payments p ON p.enrollment_id = e.enrollment_id
GROUP BY c.course_id
HAVING COUNT(e.enrollment_id) >= 2;

--   3. Thanh tra học phí (Nợ cước):
SELECT e.enrollment_id  "mã ĐK",
       s.student_id     "mã HV",
       s.student_name   "họ tên",
       e.subscribe_date "ngày đăng ký"
FROM Enrollments e
         LEFT JOIN Students s ON s.student_id = e.student_id
         LEFT JOIN Courses c ON c.course_id = e.course_id
         LEFT JOIN Payments p ON p.enrollment_id = e.enrollment_id
WHERE amount IS NULL;

--   4. Phân tích khách hàng thân thiết (VIP):
SELECT s.student_id   "mã HV",
       s.student_name "họ tên",
       s.email AS     email,
       SUM(amount)    "Tổng tiền"
FROM Enrollments e
         JOIN Students s ON s.student_id = e.student_id
         JOIN Courses c ON c.course_id = e.course_id
         JOIN Payments p ON p.enrollment_id = e.enrollment_id
GROUP BY s.student_id
HAVING SUM(amount) >= 1000000;

-- VI. View, Trigger, Function/Procedure – Hướng nghiệp vụ thực tế
--   1. View: Khóa học mới ghi danh – vw_RecentEnrollments
CREATE VIEW vw_RecentEnrollments AS
SELECT s.student_name "họ tên học viên",
       c.course_name  "tên khóa học",
       subscribe_date "ngày đăng ký",
       enroll_status  "trạng thái"
FROM Enrollments e
         JOIN Students s ON s.student_id = e.student_id
         JOIN Courses c ON c.course_id = e.course_id
WHERE subscribe_date > '2025-06-01'
ORDER BY subscribe_date DESC;

SELECT *
FROM vw_RecentEnrollments;

--   2. View: Doanh thu khóa học cao – vw_HighRevenueCourses
CREATE VIEW vw_HighRevenueCourses AS
SELECT c.course_name "tên khóa học", c.category "thể loại", SUM(amount) "tổng doanh thu"
FROM Enrollments e
         JOIN Students s ON s.student_id = e.student_id
         JOIN Courses c ON c.course_id = e.course_id
         JOIN Payments p ON p.enrollment_id = e.enrollment_id
GROUP BY c.course_id
HAVING SUM(amount) > 1000000;

SELECT *
FROM vw_HighRevenueCourses;

--   3. Trigger: Kiểm tra logic ngày thanh toán – tg_check_payment_date
CREATE OR REPLACE FUNCTION fn_check_payment_date()
    RETURNS TRIGGER AS
$$
DECLARE
    v_subscribe_date DATE;
BEGIN
    SELECT subscribe_date
    INTO v_subscribe_date
    FROM Enrollments
    WHERE NEW.enrollment_id = enrollment_id;

    IF v_subscribe_date > NEW.payment_date THEN
        RAISE EXCEPTION 'Lỗi: Ngày thanh toán cần sau ngày đăng ký';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_check_payment_date
    BEFORE INSERT OR UPDATE
    ON Payments
    FOR EACH ROW
EXECUTE FUNCTION fn_check_payment_date();

--Case lỗi
INSERT INTO Payments(payment_id, enrollment_id, payment_method, payment_date, amount)
VALUES ('PA008', 'EN005', 'Credit Card', '2025-06-03', 850000);

UPDATE Payments
SET payment_date = '2025-06-02'
WHERE payment_id = 'PA004';
--Case thành công
INSERT INTO Payments(payment_id, enrollment_id, payment_method, payment_date, amount)
VALUES ('PA008', 'EN005', 'Credit Card', '2025-06-06', 850000);

UPDATE Payments
SET payment_date = '2025-06-08'
WHERE payment_id = 'PA004';

--     4. Trigger: Cập nhật sĩ số lớp học – tg_update_student_count
CREATE OR REPLACE FUNCTION fn_update_student_count()
    RETURNS TRIGGER AS
$$
BEGIN
    UPDATE Courses
    SET number_of_student = number_of_student + 1
    WHERE course_id = NEW.course_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_update_student_count
    AFTER INSERT
    ON Enrollments
    FOR EACH ROW
EXECUTE FUNCTION fn_update_student_count();

-- test insert
INSERT INTO Enrollments(enrollment_id, student_id, course_id, subscribe_date, enroll_status)
VALUES ('EN010', 'S002', 'C001', '2025-06-05', 'Đang học');

-- 5. Procedure: Thêm khóa học mới – sp_add_course
CREATE OR REPLACE PROCEDURE sp_add_course(p_course_id VARCHAR(10), p_course_name VARCHAR(100), p_category VARCHAR(50)
, p_fee NUMERIC(12, 2))
    LANGUAGE plpgsql
AS
$$
BEGIN
    INSERT INTO Courses(course_id, course_name, category, course_fee)
    VALUES (p_course_id, p_course_name, p_category, p_fee);
END;
$$;

-- call test procedure
CALL sp_add_course('C010', 'Python advanced', 'Lập trình', 1200000);

-- 6. Procedure: Chuyển đổi khóa học – sp_switch_course
CREATE OR REPLACE PROCEDURE sp_switch_course(p_enroll_id VARCHAR(10), p_course_id VARCHAR(10))
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_old_course_id VARCHAR(10);
BEGIN
    SELECT course_id INTO v_old_course_id
    FROM Enrollments
    WHERE enrollment_id = p_enroll_id;

    -- update old course
    UPDATE Courses
    SET number_of_student = number_of_student - 1
    WHERE course_id = v_old_course_id;

    -- update new course
    UPDATE Courses
    SET number_of_student = number_of_student + 1
    WHERE course_id = p_course_id;

    -- update Enrollments
    UPDATE Enrollments
    SET course_id = p_course_id
    WHERE enrollment_id = p_enroll_id;
END;
$$;

-- call test
CALL sp_switch_course('EN004', 'C001');





