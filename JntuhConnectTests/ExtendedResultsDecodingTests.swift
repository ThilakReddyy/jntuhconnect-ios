import Foundation
import Testing
@testable import JntuhConnect

struct ExtendedResultsDecodingTests {
    @Test func decodesAllResultAttempts() throws {
        let data = Data(#"{"details":{"collegeCode":"E51","fatherName":"Parent","name":"Student","rollNumber":"18E51A0479","branch":"ECE"},"results":[{"semester":"1-1","exams":[{"examCode":"101","rcrv":false,"graceMarks":false,"subjects":[{"credits":3,"externalMarks":60,"grades":"A","internalMarks":20,"subjectCode":"M1","subjectName":"Math","totalMarks":80}]}]}]}"#.utf8)
        let response = try JSONDecoder().decode(AllResultsResponse.self, from: data)
        #expect(response.results.first?.exams.first?.subjects.first?.subjectCode == "M1")
    }

    @Test func decodesCreditsAndContrastFlexibleNumbers() throws {
        let credits = Data(#"{"details":null,"results":{"academicYears":[{"semesterWiseCredits":{"1-1":20.5},"creditsObtained":20.5,"totalCredits":18}],"totalCredits":160,"totalObtainedCredits":150.5,"totalRequiredCredits":160}}"#.utf8)
        let creditResponse = try JSONDecoder().decode(CreditsResponse.self, from: credits)
        #expect(creditResponse.results?.totalObtainedCredits == 150.5)

        let contrast = Data(#"{"studentProfiles":[{"name":"One","rollNumber":"18E51A0479","collegeCode":"E51","fatherName":"P","CGPA":6.55,"backlogs":0,"credits":160}],"semesters":[[{"semester":"1-1","semesterSGPA":"7.0","semesterCredits":20.5,"semesterGrades":140,"backlogs":0,"failed":false}]]}"#.utf8)
        let contrastResponse = try JSONDecoder().decode(ResultContrastResponse.self, from: contrast)
        #expect(contrastResponse.studentProfiles.first?.cgpa == "6.55")
        #expect(contrastResponse.semesters.first?.first?.credits == "20.5")
    }

    @Test func classResultAcceptsEmptyArrayForMissingStudentResult() throws {
        let data = Data(#"[{"details":{"collegeCode":"E51","fatherName":"P","name":"Student","rollNumber":"18E51A0479","branch":"ECE"},"results":[]}]"#.utf8)
        let students = try JSONDecoder().decode([ClassResultStudent].self, from: data)
        #expect(students.first?.results == nil)
    }

    @Test func classBacklogAcceptsEmptyArrayForUnsyncedStudent() throws {
        let data = Data(#"[{"details":{"collegeCode":"E51","fatherName":"P","name":"Student","rollNumber":"18E51A0479","branch":"ECE"},"results":[]}]"#.utf8)
        let students = try JSONDecoder().decode([ClassBacklogStudent].self, from: data)

        #expect(students.first?.results == nil)
    }
}
