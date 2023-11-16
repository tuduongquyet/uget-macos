// Compile:
// clang -fobjc-arc -arch arm64 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -mmacosx-version-min=11 -O2 -framework Foundation -framework AppKit -framework CoreFoundation -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include Launcher/uget/uget/main.m -o Launcher/uget/build/Release/uGet

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

#include <dlfcn.h>

#define UGET_CONFIG_DIR [@"~/.config/uGet" stringByExpandingTildeInPath]
#define CONFIG_FILE [UGET_CONFIG_DIR stringByAppendingPathComponent:@"uget_mac.conf"]

#define THEME_KEY @"theme"
#define LOCALE_KEY @"locale"
#define IM_MODULE_KEY @"im_module"

#define MY_ARG_MAX (16 * 1024)

@interface UGetConfigValue : NSObject

@property (nonatomic, copy) NSString *value;
@property (nonatomic, copy) NSString *description;
@property (nonatomic, assign) BOOL isPresent;

+ (UGetConfigValue *)valueWithDefault:(NSString *)defaultComment comment:(NSString *)comment;

@end

@implementation UGetConfigValue

@synthesize value;
@synthesize description;

+ (UGetConfigValue *)valueWithDefault:(NSString *)defaultComment comment:(NSString *)comment {
    UGetConfigValue *configValue = [[UGetConfigValue alloc] init];
    configValue.value = defaultComment;
    configValue.description = comment;
    configValue.isPresent = NO;
    return configValue;
}

@end

NSDictionary<NSString *, UGetConfigValue *> *ugetConfig = nil;

static void readUGetConfig(void) {
    NSString *fileContent = [NSString stringWithContentsOfFile:CONFIG_FILE encoding:NSUTF8StringEncoding error:nil];
    if (fileContent == nil) {
        return;
    }
    
    NSArray<NSString *> *lines = [fileContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString *line in lines) {
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray<NSString *> *keyValue = [trimmedLine componentsSeparatedByString:@"="];
        if (keyValue.count != 2) {
            continue;
        }
        NSString *key = [keyValue[0] lowercaseString];
        if (ugetConfig[key] != nil) {
            ugetConfig[key].value = keyValue[1];
            ugetConfig[key].isPresent = YES;
        }
    }
}

static BOOL writeToFile(NSString *content, NSString *path) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSError *error = nil;
    BOOL success = [content writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:&error];
    
    if (!success) {
        NSLog(@"Failed to write config file into %@: %@", path, error.localizedDescription);
    }
    
    return success;
}

static void writeUGetConfigIfNeeded(void) {
    BOOL updateConfig = NO;
    for (NSString *key in ugetConfig) {
        if (!ugetConfig[key].isPresent) {
            updateConfig = YES;
            break;
        }
    }
    if (!updateConfig) {
        return;
    }
    
    NSMutableString *configFileContent = [[NSMutableString alloc] init];
    [configFileContent appendString:@"[Settings]\n"];
    
    for (NSString *key in ugetConfig) {
        [configFileContent appendFormat:@"# %@\n", ugetConfig[key].description];
        [configFileContent appendFormat:@"%@=%@\n", key, ugetConfig[key].value];
    }
    
    writeToFile(configFileContent, CONFIG_FILE);
}

static BOOL writeGtkConfig(void) {
    BOOL isLight = YES;
    NSString *theme = ugetConfig[THEME_KEY].value;
    
    if ([theme isEqualToString:@"1"]) {
        isLight = YES;
    } else if ([theme isEqualToString:@"2"]) {
        isLight = NO;
    } else {
        NSString *interfaceStyle = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
        if (interfaceStyle != nil) {
            isLight = [[interfaceStyle lowercaseString] isEqualToString:@"light"];
        }
    }
    
    NSString *gtkConfig = [NSString stringWithFormat:@"[Settings]\n"
                           @"gtk-menu-images=1\n"
                           @"gtk-theme-name=Prof-Gnome\n"
                           @"gtk-application-prefer-dark-theme=%@\n"
                           @"gtk-icon-theme-name=%@\n",
                           isLight ? @"0" : @"1",
                           isLight ? @"Papirus" : @"Papirus-Dark"];
    
    return writeToFile(gtkConfig, [UGET_CONFIG_DIR stringByAppendingPathComponent:@"gtk-3.0/settings.ini"]);
}

static NSString *getLocale(NSString *bundleShare) {
    if (ugetConfig[LOCALE_KEY].value.length > 0) {
        return ugetConfig[LOCALE_KEY].value;
    }
    
    NSArray<NSString *> *preferredLanguages = [NSLocale preferredLanguages];
    for (NSString *language in preferredLanguages) {
        BOOL found = NO;
        NSString *lang;
        NSArray<NSString *> *components = [language componentsSeparatedByString:@"-"];
        if (components.count > 1) {
            lang = [NSString stringWithFormat:@"%@_%@", [components[0] lowercaseString], [components[1] uppercaseString]];
            NSString *path = [NSString stringWithFormat:@"%@/locale/%@", bundleShare, lang];
            found = [[NSFileManager defaultManager] fileExistsAtPath:path];
        }
        if (!found && components.count > 0) {
            NSString *language = [components[0] lowercaseString];
            NSString *path = [NSString stringWithFormat:@"%@/locale/%@", bundleShare, language];
            found = [[NSFileManager defaultManager] fileExistsAtPath:path];
            if (found && components.count == 1) {
                lang = language;
            }
        }
        if (found) {
            return [lang stringByAppendingString:@".UTF-8"];
        }
    }
    
    return @"en_US.UTF-8";
}

static void exportEnvArray(NSDictionary<NSString *, NSString *> *dictionary) {
    for (NSString *key in dictionary) {
        setenv([key UTF8String], [dictionary[key] UTF8String], 1);
    }
}

static int fillArgvArray(const char *arr[], NSArray<NSString *> *array) {
    int i = 0;
    for (NSString *value in array) {
        arr[i] = [value UTF8String];
        i++;
        if (i == MY_ARG_MAX - 1) {
            break;
        }
    }
    arr[i] = NULL;
    return i;
}

static int runUGet(void) {
    ugetConfig = @{
        THEME_KEY : [UGetConfigValue valueWithDefault:@"0"
                                              comment:@"0: automatic selection based on system settings (requires uGet restart when changed, macOS 10.14+); 1: light; 2: dark; make sure there's no ~/.config/gtk-3.0/settings.ini file, otherwise it overrides the settings made here"],
        LOCALE_KEY : [UGetConfigValue valueWithDefault:@""
                                               comment:@"no value: autodetect; locale string: locale to be used (e.g. en_US.UTF-8)"],
        IM_MODULE_KEY : [UGetConfigValue valueWithDefault:@"quartz"
                                                  comment:@"no value: don't use any IM module; module name: use the specified module, e.g. 'quartz' for native macOS behavior, for a complete list of modules, see uGet.app/Contents/Resources/lib/gtk-3.0/3.0.0/immodules, use without the 'im-' prefix"],
    };
    
    readUGetConfig();
    writeUGetConfigIfNeeded();
    BOOL haveGtkConfig = writeGtkConfig();
    
    NSString *bundleDirectory = [[NSBundle mainBundle] bundlePath];
    NSString *bundleResources = [bundleDirectory stringByAppendingPathComponent:@"Contents/Resources"];
    NSString *bundleLib = [bundleResources stringByAppendingPathComponent:@"lib"];
    NSString *bundleShare = [bundleResources stringByAppendingPathComponent:@"share"];
    NSString *bundleEtc = [bundleResources stringByAppendingPathComponent:@"etc"];
    
    NSString *language = getLocale(bundleShare);
    
    NSMutableDictionary<NSString *, NSString *> *environmentVariables = [@{
        @"XDG_CONFIG_DIRS" : haveGtkConfig ? UGET_CONFIG_DIR : bundleEtc,
        @"XDG_DATA_DIRS" : bundleShare,
        @"GIO_MODULE_DIR" : [bundleLib stringByAppendingPathComponent:@"gio/modules"],
        @"GTK_PATH" : bundleResources,
        @"GTK_EXE_PREFIX" : bundleResources,
        @"GTK_DATA_PREFIX" : bundleResources,
        @"GDK_PIXBUF_MODULE_FILE" : [bundleLib stringByAppendingPathComponent:@"gdk-pixbuf-2.0/2.10.0/loaders.cache"],
        @"LANG" : language,
        @"LC_MESSAGES" : language,
        @"LC_MONETARY" : language,
        @"LC_COLLATE" : language,
        @"LC_ALL" : language,
        @"UGET_PLUGINS_SHARE_PATH" : [bundleShare stringByAppendingPathComponent:@"uget-plugins"],
    } mutableCopy];
    
    if (ugetConfig[IM_MODULE_KEY].value.length > 0) {
        environmentVariables[@"GTK_IM_MODULE"] = ugetConfig[IM_MODULE_KEY].value;
        environmentVariables[@"GTK_IM_MODULE_FILE"] = [bundleLib stringByAppendingPathComponent:@"gtk-3.0/3.0.0/immodules.cache"];
    } else {
        environmentVariables[@"GTK_IM_MODULE_FILE"] = [bundleLib stringByAppendingPathComponent:@"gtk-3.0/3.0.0/immodules.cache1"];
    }
    
    NSMutableArray<NSString *> *arguments = [NSProcessInfo.processInfo.arguments mutableCopy];
    
    if (arguments.count > 1 && [arguments[1] hasPrefix:@"-psn_"]) {
        [arguments removeObjectAtIndex:1];
    }
        
    NSString *verboseParameter = @"--osx-verbose";
    if ([arguments containsObject:verboseParameter]) {
        [arguments removeObject:verboseParameter];
        NSLog(@"env: %@", environmentVariables);
        NSLog(@"argv: %@", arguments);
    }
    
    exportEnvArray(environmentVariables);
    
    NSWindow.allowsAutomaticWindowTabbing = NO;
    
    const char *argv[MY_ARG_MAX];
    int argc = fillArgvArray(argv, arguments);

    NSString *ugetGtkPath = [[NSBundle mainBundle] executablePath];
    NSString *ugetDirectory = [ugetGtkPath stringByDeletingLastPathComponent];
    NSString *ugetGtkBinaryPath = [ugetDirectory stringByAppendingPathComponent:@"uGet-bin"];

    int ret = execv([ugetGtkBinaryPath UTF8String], (char **)argv);

    NSLog(@"execv() failed with error code %d", ret);
    return ret;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        return runUGet();
    }
}
