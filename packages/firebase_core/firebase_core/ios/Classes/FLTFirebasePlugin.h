// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Firebase/Firebase.h>
#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>

/**
 * Block that is capable of sending a success response to a method call operation.
 * Use this for returning success data to a Method call.
 */
typedef void (^FLTFirebaseMethodCallSuccessBlock)(id _Nullable result);

/**
 * Block that is capable of sending an error response to a method call operation.
 * Use this for returning error information to a Method call.
 */
typedef void (^FLTFirebaseMethodCallErrorBlock)(NSString *_Nonnull code, NSString *_Nonnull message,
                                                NSDictionary *_Nullable details,
                                                NSError *_Nullable error);

/**
 * A protocol that all FlutterFire plugins should implement.
 */
@protocol FLTFirebasePlugin <NSObject>
/**
 * FlutterFire plugins implementing FLTFirebasePlugin must provide this method to provide it's
 * constants that are initialized during FirebaseCore.initializeApp in Dart.
 *
 * @param registrar A helper providing application context and methods for
 *     registering callbacks.
 */
@required
- (NSDictionary *_Nonnull)pluginConstantsForFIRApp:(FIRApp *_Nonnull)firebaseApp;

/**
 * The Firebase library name of the plugin, used by
 * [FIRApp registerLibrary:firebaseLibraryName withVersion:] to
 * register this plugin with the Firebase backend.
 *
 * Usually this is provided by the 'LIBRARY_NAME' preprocessor definition
 * defined in the plugins .podspec file.
 */
@required
- (NSString *_Nonnull)firebaseLibraryName;

/**
 * The Firebase library version of the plugin, used by
 * FIRApp registerLibrary:withVersion:firebaseLibraryVersion] to
 * register this plugin with the Firebase backend.
 *
 * Usually this is provided by the 'LIBRARY_VERSION' preprocessor definition
 * defined in the plugins .podspec file.
 */
@required
- (NSString *_Nonnull)firebaseLibraryVersion;

/**
 * FlutterFire plugins implementing FLTFirebasePlugin must provide this method to provide
 * its main method channel name, used by FirebaseCore.initializeApp in Dart to identify
 * constants specific to a plugin.
 */
@required
- (NSString *_Nonnull)flutterChannelName;
@end

/**
 * An interface represent a returned result from a Flutter Method Call.
 */
@interface FLTFirebaseMethodCallResult : NSObject
+ (instancetype _Nonnull)createWithSuccess:(FLTFirebaseMethodCallSuccessBlock _Nonnull)successBlock
                             andErrorBlock:(FLTFirebaseMethodCallErrorBlock _Nonnull)errorBlock;

/**
 * Submit a result indicating a successful method call.
 *
 * E.g.: `result.success(nil);`
 */
@property(readonly, nonatomic) FLTFirebaseMethodCallSuccessBlock _Nonnull success;

/**
 * Submit a result indicating a failed method call.
 *
 * E.g.: `result.error(@"code", @"message", nil);`
 */
@property(readonly, nonatomic) FLTFirebaseMethodCallErrorBlock _Nonnull error;

@end

@interface FLTFirebasePlugin : NSObject
/**
 * Creates a standardized instance of FlutterError using the values returned through
 * FLTFirebaseMethodCallErrorBlock.
 *
 * @param code Error Code.
 * @param message Error Message.
 * @param details Optional dictionary of additional key/values to return to Dart.
 * @param error Optional NSError that this error relates to.
 *
 * @return FlutterError
 */
- (FlutterError *_Nonnull)createFlutterErrorFromCode:(NSString *_Nonnull)code
                                             message:(NSString *_Nonnull)message
                                     optionalDetails:(NSDictionary *_Nullable)details
                                  andOptionalNSError:(NSError *_Nullable)error;

/**
 * Converts the '[DEFAULT]' app name used in dart and other SDKs to the '__FIRAPP_DEFAULT' iOS
 * equivalent.
 *
 * If name is not '[DEFAULT]' then just returns the same name that was passed in.
 *
 * @param appName The name of the Firebase App.
 *
 * @return NSString
 */
- (NSString *_Nonnull)firebaseAppNameFromDartName:(NSString *_Nonnull)appName;

/**
 * Converts the '__FIRAPP_DEFAULT' app name used in iOS to '[DEFAULT]' - used in Dart & other SDKs.
 *
 * If name is not '__FIRAPP_DEFAULT' then just returns the same name that was passed in.
 *
 * @param appName The name of the Firebase App.
 *
 * @return NSString
 */
- (NSString *_Nonnull)firebaseAppNameFromIosName:(NSString *_Nonnull)appName;

/**
 * Retrieves a FIRApp instance based on the app name provided from Dart code.
 *
 * @param appName The name of the Firebase App.
 *
 * @return FIRApp - returns nil if Firebase app does not exist.
 */
- (FIRApp *_Nullable)firebaseAppNamed:(NSString *_Nonnull)appName;
@end
