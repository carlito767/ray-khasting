let project = new Project('template-kha');
// LDtk
project.addLibrary('deepnightLibs');
project.addLibrary('ldtk-haxe-api');

project.addAssets('Assets/**');
project.addShaders('Shaders/**');
project.addSources('Sources');
resolve(project);
