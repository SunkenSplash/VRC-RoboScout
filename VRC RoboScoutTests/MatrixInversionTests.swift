//
//  MatrixInversionTests.swift
//  VRC RoboScoutTests
//
//  Created by William Castro on 11/20/23.
//

import XCTest
import Matft

class MatrixInversionTests: XCTestCase {
    
    func testPseudoInverse() {
            // Test 1: Regular matrix inversion
            let matrix1 = MfArray([[2, 0], [0, 3]])
            let expectedPinv1 = MfArray([[0.5, 0], [0, 1.0/3.0]])
            let pinv1 = try? Matft.linalg.pinv(matrix1)
            XCTAssertNotNil(pinv1, "Regular matrix inversion should succeed")
            XCTAssertEqual(pinv1, expectedPinv1, "Incorrect result for regular matrix inversion")

            // Test 2: Singular matrix (should fail)
            let matrix2 = MfArray([[1, 2], [1, 2]])
            XCTAssertThrowsError(try Matft.linalg.pinv(matrix2), "Singular matrix inversion should fail")

            // Test 3: Square matrix inversion
            let matrix3 = MfArray([[1, 2, 3], [3, 2, 1], [2, 1, 3]])
        let expectedPinv3 = MfArray([[-0.416667, 0.25, 0.333333],
                                     [0.583333, 0.25, -0.666667],
                                     [0.0833333, -0.25, 0.333333]])
            let pinv3 = try? Matft.linalg.pinv(matrix3)
            XCTAssertNotNil(pinv3, "Square matrix inversion should succeed")
            XCTAssertEqual(pinv3, expectedPinv3, "Incorrect result for square matrix inversion")

            // Test 4: Rectangular matrix inversion
            let matrix4 = MfArray([[1, 2, 3], [4, 5, 6]])
            let expectedPinv4 = MfArray([[-0.9444444444444444, 0.4444444444444444],
                                         [0.8888888888888888, -0.7777777777777778],
                                         [-0.2222222222222222, 0.3333333333333333]])
            let pinv4 = try? Matft.linalg.pinv(matrix4)
            XCTAssertNotNil(pinv4, "Rectangular matrix inversion should succeed")
            XCTAssertEqual(pinv4, expectedPinv4, "Incorrect result for rectangular matrix inversion")
        }
}
