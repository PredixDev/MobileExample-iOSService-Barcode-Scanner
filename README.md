# MobileExample-iOSService-Barcode-Scanner
This repo demonstrates a barcode scanning iOS native service and a web app utilizing that service.

## Prerequisites
It is assumed you already have a Predix Mobile sevice installation, have installed the Predix Mobile pm command line tool, and have installed a Predix Mobile iOS Container, following the Getting Started examples for those repos.

It is also assumed you have a basic knowledge of mobile iOS development using XCode and Swift.

To get started, follow this documentation:
* [Get Started with the Mobile Service and Mobile SDK] (https://www.predix.io/docs#rae4EfJ6) 
* [Running the Predix Mobile Sample App] (https://www.predix.io/docs#EGUzWwcC)
* [Creating a Mobile Hello World Web App] (https://www.predix.io/docs#DrBWuHkl) 


## Step 1 - Integrate the example code

1. Add the `BarcodeScannerService.swift` file from this repo to your container project.
2. Open your Predix Mobile container app project. 
3. In the Project Manager in left-hand pane, expand the PredixMobileReferenceApp project, then expand the PredixMobileReferenceApp group. Within that group, expand the Classes group. 
4. In this group, create a group called "Services".
5.Add the file `BarcodeScannerService.swift` to this group, either by dragging from Finder, or by using the Add Files dialog in XCode. When doing this, ensure the BarcodeScannerService.swift file is copied to your project, and added to your PredixMobileReferenceApp target.

## Step 2 - Register your new service

The `BarcodeScannerService.swift` file contains all the code needed for our example service, but you must register the service in the container in order for it to be available to your web app. Add a line of code to `AppDelegate`.

1. In the `AppDelegate.swift` file, navigate to the application: didFinishLaunchingWithOptions: method. In this method, you will see a line that looks like this:

  'PredixMobilityConfiguration.loadConfiguration()'

2. Directly after that line, add the following:

  'PredixMobilityConfiguration.additionalBootServicesToRegister = [BarcodeScannerService.self]'
  
This informs the iOS Predix Mobile SDK framework to load your new service when the app starts, thus making it available to your web app.

## Step 3 - Review the code

The Swift files you added to your container are heavily documented. Read through these for a full understanding of how they work, and what they are doing.

The comments take you through creating an implemenation of the `ServiceProtocol` protocol, handling requests to the service with this protocol, and returning data or error status codes to callers.

## Step 4 - Run the unit tests

## Step 5 - Call the service from a webapp

Your new iOS client service is exposed through the service identifier "barcodescanner". So calling http://pmapi/barcodescanner from a web app will call this service.

A simple demo web app is provided in the demo-webapp directory in the git repo.
