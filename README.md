# MobileExample-iOSService-Barcode-Scanner
This repo demonstrates a barcode scanning iOS native service and a webapp utilizing that service.

## Step 0 - Prerequisites
It is assumed you already have a Predix Mobile cloud services installation, have installed the Predix Mobile command line tool, and have installed a Predix Mobile iOS Container, following the Getting Started examples for those repos.

It is also assumed you have a basic knowledge of mobile iOS development using XCode and Swift.

## Step 1 - Integrate the example code

Here you will add the BarcodeScannerService.swift file from this repo to your container project.

Open your Predix Mobile container app project. In the Project Manager in left-hand pane, expand the PredixMobileReferenceApp project, then expand the PredixMobileReferenceApp group. Within that group, expand the Classes group. In this group, create a group called "Services".

Add the file BarcodeScannerService.swift to this group, either by dragging from Finder, or by using the Add Files dialog in XCode. When doing this, ensure the BarcodeScannerService.swift file is copied to your project, and added to your PredixMobileReferenceApp target.

## Step 2 - Register your new service

The BarcodeScannerService.swift file contains all the code needed for our example service, however we still need to register our service in the container in order for it to be available to our webapp. In order to do this, we will add a line of code to our AppDelegate.

In the AppDelegate.swift file, navigate to the application: didFinishLaunchingWithOptions: method. In this method, you will see a line that looks like this:

PredixMobilityConfiguration.loadConfiguration()
Directly after that line, add the following:

PredixMobilityConfiguration.additionalBootServicesToRegister = [BarcodeScannerService.self]
This will inform the iOS Predix Mobile SDK framework to load your new service when the app starts, thus making it available to your webapp.

## Step 3 - Review the code

The Swift files you added to your container are heavily documented. Read through these for a full understanding of how they work, and what they are doing.

In brief - they take you through creating an implemenation of the ServiceProtocol protoccol, handling requests to the service with this protocol, and returning data or error status codes to callers.

## Step 4 - Run the unit tests.


## Step 5 - Call the service from a webapp

Your new iOS client service is exposed through the service identifier "barcodescanner". So calling http://pmapi/barcodescanner from a webapp will call this service.

A simple demo webapp is provided in the demo-webapp directory in the git repo.
