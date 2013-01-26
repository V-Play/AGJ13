#include <QApplication>

#include "qmlapplicationviewer.h"
#include "vplayapplication.h"


Q_DECL_EXPORT int main(int argc, char *argv[])
{
  QScopedPointer<QApplication> app(createApplication(argc, argv));
  
  VPlayApplication vplayApplication;
  
  // the default mainQmlFileName is qml/main.qml - if you want to change the entry qml file, change it here before startApplication() is called
  vplayApplication.setMainQmlFileName("qml/AGJMain.qml");
  
  // V-Play has 2 renderers:
  // * the performance optimized CocosRenderer: this is the default renderer on all platforms and has a better performance than QmlRenderer; its only limitation is that not all QML items are fully supported, and no debug shapes of physics objects are available
  // * the QmlRenderer is primarily needed for debugging of physics games on desktops    
  //    vplayApplication.setCocosRendererEnabled(false);
//  vplayApplication.setQmlRendererEnabled(false);
  
  // this must be called in each game before startApplication() is called, so the import VPlay 1.0 can be resolved
  Q_INIT_RESOURCE(resources_vplay);
  
  return vplayApplication.startApplication();
  
}

