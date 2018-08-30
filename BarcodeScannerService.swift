//
//  BarcodeScannerService.swift
//  PredixMobileReferenceApp
//
//  Created by GE Degital on 2/18/16.
//  Copyright © 2016 GE. All rights reserved.
//

/**
    The purpose of this very simple service is to demonstrate the key components of writing a
    Predix Mobile client service.
    This service takes no parameters, and returns the scanned barcode/error as a JSON object.
*/

import Foundation
import AVFoundation
import UIKit

/// import the PredixMobile framework, so Swift can find the PredixMobile components we'll need
import PredixMobileSDK

/// As this protocol is defined as Obj-C compatible, the implementer must be an Obj-C compatible class.
@objc class BarcodeScannerService: NSObject, ServiceProtocol {

    /// - Note:
    /// ServiceProtocol's properties and methods are all defined as static, and no class implementation of your service is ever created.
    /// This is a purposeful architectural decision. Services should be stateless and interaction with them ephemeral. A static
    /// object enforces this direction.

    /// the serviceIdentifier property defines first path component in the URL of the service.
    static var serviceIdentifier: String {get { return "barcodescanner" }}

// MARK: performRequest - entry point for request
    /**
        performRequest is the meat of the service. It is where all requests to the service come in.

        The request parameter will contain all information the caller has provided for the request, this will include the URL,
        the HTTP Method, and in the case of a POST or PUT, any HTTP body data.
        The nature of services are asynchronous. So this method has no return values, it communicates with its caller through three
        blocks or closures. These three are the parameters responseReturn, dataReturn, and requestComplete. This follows the general
        nature of a web-based HTTP interaction.

        - parameters:
            - responseReturn    : generally every call to performRequest should call responseReturn once, and only once. The call requires an
            NSHTTPResponse object, and a default object is provided as the "response" parameter. The response object can be returned directly,
            or can be used as a container for default values, and a new NSHTTPResponse can be built from it. The default response parameter's
            status code is 200 (OK), so error conditions will not return the response object unaltered. (See the respondWithErrorStatus methods,
            and the createResponse method documentation below for helpers in creating other response objects.)

            - dataReturn        : Services that return data, and not just a status code will use the dataReturn parameter to return data. Generally
            this block will be called once, however it could be called multiple times to return particularly large amounts of data in a
            chunked fashion. Again, this behavior follows general web-based HTTP interaction. If used, the dataReturn block should be called after
            the responseReturn block is called, and before the responseComplete block is called.

            - requstComplete    : this block indicates to the caller that the service has completed processing, and the call is complete. The requestComplete
            block must be called, and it must be called only once per performRequest call. Once the requestComplete block is called, no additional
            processing should happen in the service, and no other blocks should be called.
    */
    static func performRequest(_ request: URLRequest, response: HTTPURLResponse, responseReturn : @escaping responseReturnBlock, dataReturn : @escaping dataReturnBlock, requestComplete: @escaping requestCompleteBlock) {

        /// First let's examine the request. In this example, we're going to expect only a GET request, and the URL path should only be the serviceIdentifier

        /// we'll use a guard statement here just to verify the request object is valid. The HTTPMethod and URL properties of a NSURLRequest
        /// are optional, and we need to ensure we're dealing with a request that contains them.
        guard let url = request.url else {
            /**
                if the request does not contain a URL or a HTTPMethod, then we return a error. We'll also return an error if the URL
                does not contain a path. In a normal interaction this would never happen, but we need to be defensive and expect anything.

                we'll use one of the respondWithErrorStatus methods to return an error condition to the caller, in this case,
                a status code of 400 (Bad Request).

                Note that the respondWithErrorStatus methods all take the response object, the reponseReturn block and the requestComplete
                block. This is because the respondWithErrorStatus constructs an appropriate NSHTTPURLResponse object, and calls
                the reponseReturn and requestComplete blocks for you. Once a respondWithErrorStatus method is called, the performRequest
                method should not continue processing and should always return.
            */
            self.respondWithErrorStatus(.badRequest, response, responseReturn, requestComplete)
            return
        }

        /**
            Now that we know we have a path and method string, let's examine them for our expected values.
            For this example we'll return an error if the url has any additional path or querystring parameters.
            We'll also return an error if the method is not the expected GET HTTP method. The HTTP Status code convention
            has standard codes to return in these cases, so we'll use those.
        */

        /**
            Path in this case should match the serviceIdentifier, or "barcodescanner". We know the serviceIdentifier is all
            lower case, so we ensure the path is too before comparing.
            In addition, we expect the query string to be nil, as no query parameters are expected in this call.
            In your own services you may want to be more lenient, simply ignoring extra path or parameters.
        */

        guard url.path.lowercased() == "/\(self.serviceIdentifier)" && url.query == nil else {
            /// In this case, if the request URL is anything other than "http://pmapi/barcodescanner" we're returning a 400 status code.
            self.respondWithErrorStatus(.badRequest, response, responseReturn, requestComplete)
            return
        }

        /// now that we know our path is what we expect, we'll check the HTTP method. If it's anything other than "GET"
        /// we'll return a standard HTTP status used in that case.
        guard request.httpMethod == "GET" else {
            /// According to the HTTP specification, a status code 405 (Method not allowed) must include an Allow header containing a list of valid methods.
            /// this  demonstrates one way to accomplish this.
            let headers = ["Allow": "GET"]

            /// This respondWithErrorStatus overload allows additional headers to be passed that will be added to the response.
            self.respondWithErrorStatus(Http.StatusCode.methodNotAllowed, response, responseReturn, requestComplete, headers)
            return
        }

        /// Now we know that our path and method were correct, and we've handled error conditions, let's try scanning barcodes.
        let scanner = BarcodeScanner.sharedInstance
        scanner.scanBarcode(
            /// error handling closure
            errorReturn: { (error : Data?) -> Void in

                /// the default response object is always pre-set with a 200 (OK) response code, so can be directly used when there are no problems.
                responseReturn(response)

                /// we return the JSON object containing error details
                dataReturn(error)

                /// An inform the caller the service call is complete
                requestComplete()
            },
            /// success handling closure
            barcodeReturn: { (barcode: Data?) -> Void in

                /// the default response object is always pre-set with a 200 (OK) response code, so can be directly used when there are no problems.
                responseReturn(response)

                /// we return the JSON object for barcode
                dataReturn(barcode)

                /// An inform the caller the service call is complete
                requestComplete()

            }
        )

    }

}

// MARK: Barcodescanner
/**
    Responsible for camera access and scanning barcode
*/
@objc class BarcodeScanner: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    ///  a shared instance
    static let sharedInstance       = BarcodeScanner()

    typealias barcodeReturnBlock    = (Data?) -> Void
    typealias errorReturnBlock      = (Data?) -> Void

    private var mErrorReturn: errorReturnBlock?
    private var mBarcodeReturn: barcodeReturnBlock?

    private var avCaptureSession: AVCaptureSession?
    private var avCaptureVideoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var avCaptureMetadataOutput: AVCaptureMetadataOutput?

    private var responseData: [String : Any]?
    private var topViewController: UIViewController?
    private var btnDone: UIButton?

    /// supported barcodes
    let supportedBarcodes = [AVMetadataObject.ObjectType.qr, AVMetadataObject.ObjectType.code128, AVMetadataObject.ObjectType.code39, AVMetadataObject.ObjectType.code93, AVMetadataObject.ObjectType.upce, AVMetadataObject.ObjectType.pdf417, AVMetadataObject.ObjectType.ean13, AVMetadataObject.ObjectType.aztec]

    override init () {
        super.init()

    }

    deinit {

    }

    /**
        Checks for camera access and if camera access provided starts scanning for barcode.
        - parameter:
            - errorReturnBlock      :   (Data?) -> Void
            - barcodeReturnBlock    :   (Data?) -> Void
    */
    func scanBarcode(errorReturn : @escaping errorReturnBlock, barcodeReturn : @escaping barcodeReturnBlock) {
        self.mErrorReturn   = errorReturn
        self.mBarcodeReturn = barcodeReturn

        self.checkCamera()

    }

// MARK: private functions
    /**
        gets viewcontrolller which is presented on screen
    */
    internal func getTopVC() -> UIViewController {
        var toReturn: UIViewController?
        if let topController = UIApplication.shared.keyWindow?.rootViewController {
            if(topController.presentedViewController == nil) {
                toReturn = topController
            } else {
                while let presentedViewController = topController.presentedViewController {
                    toReturn = presentedViewController
                    break
                }
            }
        }
        return toReturn!
    }

    /**
        returns a response to calling closure
    */
    internal func sendResponse(msg: String, isError: Bool) /*-> Data*/ {
        self.responseData = [String: Any]()
        if(isError) {
            self.responseData!["error"] = msg
        } else {
            self.responseData!["barocde"] = msg
        }

        do {
            let toReturn = try JSONSerialization.data(withJSONObject: self.responseData!, options: JSONSerialization.WritingOptions(rawValue: 0))
            if(isError) {
                self.mErrorReturn!(toReturn)
            } else {
                self.mBarcodeReturn!(toReturn)
            }
        } catch let error {
            Logger.error("Error serializing user data into JSON: \(error)")
        }

    }

    /**
        Checks camera access and acts acordingly
    */
    internal func checkCamera() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authStatus {

        case .authorized:
            startCapture()
            break

        case .denied:
            self.sendResponse(msg: "Denied - User has already denied access to camera.", isError: true)
            break

        case .restricted:
            self.sendResponse(msg: "Restricted - User not authorized to access camera.", isError: true)
            break

        case .notDetermined:
            /// permission dialog not yet presented, requesting authorization now
            AVCaptureDevice.requestAccess(for: AVMediaType.video,
                completionHandler: { (granted: Bool) -> Void in
                    if granted {
                        print("access granted")
                        self.startCapture()
                    } else {
                        print("Denied - access denied")
                        self.sendResponse(msg: "Access to camera denied", isError: true)
                    }
            })
            break

        }
    }

    /**
        Starts video capture and display video feed on screen.
    */
    internal func startCapture() {

        /// Get the default video input device (the camera)
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            Logger.error("Error: no camera")
            self.sendResponse(msg: "No camera present", isError: true)
            return
        }

        do {
            /// Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let avCaptureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)

            /// Initialize the captureSession object.
            let captureSession = AVCaptureSession()

            /// Set the input device on the capture session.
            if captureSession.canAddInput(avCaptureDeviceInput) {
                captureSession.addInput(avCaptureDeviceInput)
            }

            /// Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()

            /// Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

            /// Set the output device on the capture session.
            if captureSession.canAddOutput(captureMetadataOutput) {
                captureSession.addOutput(captureMetadataOutput)
            }

            /// Detect all the supported bar code
            captureMetadataOutput.metadataObjectTypes = captureMetadataOutput.availableMetadataObjectTypes

            self.avCaptureSession = captureSession
            self.avCaptureMetadataOutput = captureMetadataOutput

            /// Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            self.avCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            self.avCaptureVideoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill

            self.topViewController = self.getTopVC()
            DispatchQueue.main.async {
                self.avCaptureVideoPreviewLayer?.frame = self.topViewController!.view.layer.bounds
                self.topViewController!.view.layer.addSublayer(self.avCaptureVideoPreviewLayer!)
                /// Start video capture
                self.avCaptureSession?.startRunning()
                self.addDoneButton(view: self.topViewController!.view)
            }

        } catch let error {
            Logger.error(error.localizedDescription)
            self.sendResponse(msg: "unable to start video capture - \(error)", isError: true)
        }
    }

    internal func addDoneButton(view: UIView) {
        let btnWidth: CGFloat            = 100
        let btnHeight: CGFloat           = 50

        self.btnDone                    = UIButton(type: UIButton.ButtonType.system) as UIButton
        self.btnDone!.backgroundColor   = UIColor.white
        self.btnDone!.setTitle("Done", for: UIControl.State.normal)
        self.btnDone!.frame             = CGRect(x: view.frame.size.width / 2 - btnWidth/2, y: view.frame.size.height - btnHeight, width: 100, height: 50)
        self.btnDone!.addTarget(self, action: #selector(donePressed(sender:)), for: UIControl.Event.touchUpInside)
        view.addSubview(self.btnDone!)
    }

    @objc internal func donePressed(sender: UIButton!) {
        self.sendResponse(msg: "User cancelled", isError: true)
        self.dispose()
    }

    /**
        Stops cpature process and removes camera view from screen
    */
    internal func dispose() {
        self.avCaptureMetadataOutput!.setMetadataObjectsDelegate(nil, queue: DispatchQueue.main)
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1,
                animations: {
///                   TODO: some animation if required
                },
                completion: {(_: Bool) in
                    self.btnDone!.removeFromSuperview()
                    self.avCaptureVideoPreviewLayer?.removeFromSuperlayer()
            })

        }
    }

    // MARK: Delegate for AVCapture
    /**
        whenever the output captures and emits new objects, as specified by its metadataObjectTypes property.
    */
    @objc func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        /// Check if the metadataObjects array is not nil and it contains at least one object.
        guard metadataObjects.count > 0 else {
            self.sendResponse(msg: "Barcode/QR code is detected", isError: true)
            return
        }

        if let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject {
            /// Filtering the scanned barcode type
            if supportedBarcodes.contains(metadataObj.type) {
                ///done scanning, calling dispose to stop scanning
                DispatchQueue.main.async {
                    self.dispose()
                    if let metadataString = metadataObj.stringValue {
                        print(metadataString)
                        self.sendResponse(msg: metadataString, isError: false)
                    }
                }
            }
        }
    }
}
