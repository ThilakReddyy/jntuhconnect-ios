import Foundation
import Testing
@testable import JntuhConnect

struct AcademicResultDecodingTests {
    @Test func decodesBackendAcademicResultShape() throws {
        let json = #"""
        {
          "details": {
            "collegeCode": "J2",
            "fatherName": "Parent",
            "name": "Student Name",
            "rollNumber": "22J21A0501",
            "branch": "CSE"
          },
          "results": {
            "backlogs": 0,
            "CGPA": "8.75",
            "credits": 126.5,
            "grades": 875,
            "semesters": [{
              "backlogs": 0,
              "failed": false,
              "semester": "4-1",
              "semesterCredits": 20,
              "semesterGrades": 176,
              "semesterSGPA": "8.80",
              "subjects": [{
                "credits": 3,
                "externalMarks": 58,
                "grades": "A+",
                "internalMarks": 27,
                "subjectCode": "CS701PC",
                "subjectName": "Machine Learning",
                "totalMarks": 85
              }]
            }]
          }
        }
        """#

        let response = try JSONDecoder().decode(AcademicResultResponse.self, from: Data(json.utf8))
        #expect(response.details?.name == "Student Name")
        #expect(response.results.cgpa == "8.75")
        #expect(response.results.semesters.first?.subjects.first?.grade == "A+")
    }

    @Test func decodesNumericCGPAUsedWhenBacklogsExist() throws {
        let json = #"""
        {
          "details": null,
          "results": {
            "backlogs": 2,
            "CGPA": 0.0,
            "credits": 80,
            "grades": 0,
            "semesters": []
          }
        }
        """#

        let response = try JSONDecoder().decode(AcademicResultResponse.self, from: Data(json.utf8))
        #expect(response.results.cgpa == "0")
    }
}
