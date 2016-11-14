//
//  ViewController.m
//  MyContact
//
//  Created by gogleyin on 25/10/2016.
//  Copyright © 2016 Tencent. All rights reserved.
//

#import "ViewController.h"
@import AddressBook;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *count;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
    self.count.delegate = self;
  // Do any additional setup after loading the view, typically from a nib.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.count resignFirstResponder];
    return YES;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (IBAction)deleteContact:(id)sender {
  ABAddressBookRef addressBook = CFBridgingRetain((__bridge id)(ABAddressBookCreateWithOptions(NULL, NULL)));
  int count = ABAddressBookGetPersonCount(addressBook);
  if(count == 0 && addressBook != NULL) { //If there are no contacts, don't delete
    CFRelease(addressBook);
    return;
  }
  //Get all contacts and store it in a CFArrayRef
  NSString *msg = @"Delete success.";
  CFArrayRef theArray = ABAddressBookCopyArrayOfAllPeople(addressBook);
  for(CFIndex i = 0; i < count; i++) {
    ABRecordRef person = CFArrayGetValueAtIndex(theArray, i); //Get the ABRecord
    if (!ABAddressBookRemoveRecord(addressBook, person, NULL)) {
      NSLog(@"Remove failed.");
    }
    CFRelease(person);
  }
  BOOL save = ABAddressBookSave(addressBook, NULL); //save address book state
  if(addressBook != NULL) {
    CFRelease(addressBook);
  }
  UIAlertView *contactAddedAlert = [[UIAlertView alloc]initWithTitle:msg message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
  [contactAddedAlert show];

}

- (IBAction)importContact:(id)sender {
  if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied ||
      ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted){
    NSLog(@"Denied");
    UIAlertView *cantAddContactAlert = [[UIAlertView alloc] initWithTitle: @"Cannot Add Contact" message: @"You must give the app permission to add the contact first." delegate:nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
    [cantAddContactAlert show];
  } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized){
    NSLog(@"Authorized");
    [self addContacts:[_count.text intValue]];
  } else{ //ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined
    NSLog(@"Not determined");
    ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (!granted){
          UIAlertView *cantAddContactAlert = [[UIAlertView alloc] initWithTitle: @"Cannot Add Contact" message: @"You must give the app permission to add the contact first." delegate:nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
          [cantAddContactAlert show];
          return;
        }
        [self addContacts:[_count.text intValue]];
      });
    });
  }

}

- (void)addContacts: (int) count {
  ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, nil);
  
  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"contacts" ofType:@"json"];
  NSData *data = [NSData dataWithContentsOfFile:filePath];
  NSArray *contacts = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
  
  for (int i = 0; i < count; i++) {
    ABRecordRef perseon = ABPersonCreate();
    ABMutableMultiValueRef phoneNumbers = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    ABMultiValueAddValueAndLabel(phoneNumbers, (__bridge CFStringRef)contacts[i][@"phone"], kABPersonPhoneMobileLabel, NULL);
    ABRecordSetValue(perseon, kABPersonFirstNameProperty, (__bridge CFStringRef)contacts[i][@"name"], nil);
    ABRecordSetValue(perseon, kABPersonPhoneProperty, phoneNumbers, nil);
    ABAddressBookAddRecord(addressBookRef, perseon, nil);
  }
  
  ABAddressBookSave(addressBookRef, nil);
  UIAlertView *contactAddedAlert = [[UIAlertView alloc]initWithTitle:[NSString stringWithFormat:@"%d Contact Added", count] message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
  [contactAddedAlert show];
}

- (void)deleteAllContacts {
  }

@end
