'use strict'

const { NativeModules } = require('react-native');
const { RNVideoTrimmer } = NativeModules;

const DEFAULT_OPTIONS = {
  title: 'Select a Photo',
  cancelButtonTitle: 'Cancel',
  takePhotoButtonTitle: 'Take Photo…',
  chooseFromLibraryButtonTitle: 'Choose from Library…',
  quality: 1.0,
  allowsEditing: false,
  permissionDenied: {
    title: 'Permission denied',
    text: 'To be able to take pictures with your camera and choose images from your library.',
    reTryTitle: 're-try',
    okTitle: 'I\'m sure',
  }
};

module.exports = {
  ...RNVideoTrimmer,
  showVideoTrimmer: function showVideoTrimmer(options, callback) {
    if (typeof options === 'function') {
      callback = options;
      options = {};
	}
	if (!RNVideoTrimmer.showVideoTrimmer) {
		throw new Error('showVideoTrimmer is not available on this platform');
	}
    return RNVideoTrimmer.showVideoTrimmer({...DEFAULT_OPTIONS, ...options}, callback)
  }
}
