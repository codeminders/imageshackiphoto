#import <Cocoa/Cocoa.h>
#import "ExportPluginProtocol.h"
#import "ExportPluginBoxProtocol.h"

@interface ISExportPluginBox : NSBox <ExportPluginBoxProtocol> {
	IBOutlet id <ExportPluginProtocol> mPlugin;
}

- (BOOL)performKeyEquivalent:(NSEvent *)anEvent;

@end
