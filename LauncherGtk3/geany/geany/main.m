#import <Foundation/Foundation.h>


NSString *get_locale(NSString *bundle_data)
{
    NSString *fallback = @"en_US.UTF-8";
    
    BOOL ignore_locale = [[NSFileManager defaultManager] fileExistsAtPath: [@"~/.config/geany/ignore_locale" stringByExpandingTildeInPath]];
    if (ignore_locale)
    {
        return fallback;
    }
    
    NSArray<NSString *> *langs = [NSLocale preferredLanguages];
    for (NSString *lng in langs)
    {
        BOOL found = NO;
        NSString *lang;
        NSArray<NSString *> *comps = [lng componentsSeparatedByString:@"-"];
        if (comps.count > 1)
        {
            lang = [NSString stringWithFormat:@"%@_%@", comps[0], comps[1]];
            NSString *path = [NSString stringWithFormat:@"%@/locale/%@", bundle_data, lang];
            found = [[NSFileManager defaultManager] fileExistsAtPath:path];
        }
        if (!found && comps.count > 0)
        {
            NSString *lng = comps[0];
            NSString *path = [NSString stringWithFormat:@"%@/locale/%@", bundle_data, lng];
            found = [[NSFileManager defaultManager] fileExistsAtPath:path];
            if (found && comps.count == 1)
            {
                lang = lng;
            }
        }
        if (found)
        {
            return [lang stringByAppendingString:@".UTF-8"];
        }
    }

    return fallback;
}


int run_geany()
{
    NSString *bundle_dir = [[NSBundle mainBundle] bundlePath];
    
    NSString *bundle_contents = [bundle_dir stringByAppendingPathComponent: @"Contents"];
    NSString *bundle_res = [bundle_contents stringByAppendingPathComponent: @"Resources"];
    NSString *bundle_lib = [bundle_res stringByAppendingPathComponent: @"lib"];
    NSString *bundle_data = [bundle_res stringByAppendingPathComponent: @"share"];
    NSString *bundle_etc = [bundle_res stringByAppendingPathComponent: @"etc"];

    NSString *lang = get_locale(bundle_data);

    //set environment variables
    //see https://developer.gnome.org/gtk3/stable/gtk-running.html
    NSMutableDictionary<NSString *, NSString *> *env = [[[NSProcessInfo processInfo] environment] mutableCopy];
    NSDictionary<NSString *, NSString *> *env2 = @{
        @"XDG_CONFIG_DIRS": bundle_etc,
        @"XDG_DATA_DIRS": bundle_data,

        @"GTK_PATH": bundle_res,
        @"GTK_EXE_PREFIX": bundle_res,
        @"GTK_DATA_PREFIX": bundle_res,
        @"GTK_IM_MODULE_FILE": [bundle_etc stringByAppendingPathComponent: @"gtk-3.0/gtk.immodules"],
        @"GDK_PIXBUF_MODULE_FILE": [bundle_lib stringByAppendingPathComponent: @"gdk-pixbuf-2.0/2.10.0/loaders.cache"],
        
        //Locale variables
        @"LANG": lang,
        @"LC_MESSAGES": lang,
        @"LC_MONETARY": lang,
        @"LC_COLLATE": lang,
        @"LC_ALL": lang,
        
        //Geany variables
        @"GEANY_PLUGINS_SHARE_PATH": [bundle_res stringByAppendingPathComponent: @"share/geany-plugins"],
        @"ENCHANT_MODULE_PATH": [bundle_lib stringByAppendingPathComponent: @"enchant"],
        @"GIO_MODULE_DIR": [bundle_lib stringByAppendingPathComponent: @"gio/modules"],
    };
    [env addEntriesFromDictionary: env2];
    
    //set binary name and command line arguments
    NSArray<NSString *> *argv = NSProcessInfo.processInfo.arguments;
    NSString *binary = [argv[0] stringByAppendingString:@"-bin"];
    NSMutableArray<NSString *> *args = [argv mutableCopy];
    [args removeObjectAtIndex: 0];
    
    if (args.count > 0 && [args[0] hasPrefix:@"-psn_"])
    {
        [args removeObjectAtIndex: 0];
    }

    [args addObject:[NSString stringWithFormat:@"--vte-lib=%@/libvte-2.91.0.dylib", bundle_lib]];
    
    //debugging
    NSString *verbose_param = @"--osx-verbose";
    if ([args containsObject: verbose_param])
    {
        [args removeObject:verbose_param];
        NSLog(@"env: %@", env);
        NSLog(@"args: %@", args);
        NSLog(@"binary: %@", binary);
    }
    
    //run Geany binary
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = binary;
    task.environment = env;
    task.arguments = args;
    [task launch];
    [task waitUntilExit];

    return task.terminationStatus;
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        return run_geany();
    }
    return 0;
}