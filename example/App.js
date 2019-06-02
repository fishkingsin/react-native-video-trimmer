/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 * @flow
 */

import React, {Component} from 'react';
import {
  Button,
  StyleSheet,
  View,
  Platform,
  ProgressBarAndroid,
  ProgressViewIOS,
  SafeAreaView,
} from 'react-native';
import ImagePicker from 'react-native-image-picker';
import RNVideoTrimmer from 'react-native-video-trimmer';
import Video from 'react-native-video';
import _ from 'lodash';
import PropTypes from 'prop-types';
import queryString from 'query-string';
 

const isIOS = _.isEqual(Platform.OS, 'ios');

export const ProgressBar = (props) => (
	isIOS ?
		<ProgressViewIOS
			progress={props.progress}
			progressTintColor={color.blue}
		/> :
		<ProgressBarAndroid
			styleAttr="Horizontal"
			indeterminate={false}
			progress={props.progress}
			color={color.blue}
		/>
);

ProgressBar.propTypes = {
	progress: PropTypes.number,
};

ProgressBar.defaultProps = {
	progress: 0,
};

const options = {
  title: 'Video Picker', 
  mediaType: 'video', 
  allowsEditing: false,
  storageOptions:{
    skipBackup:true,
    path:'images'
  }
};


type Props = {};
export default class App extends Component<Props> {
  
  constructor(props) {
    super(props);
    this.state = {
      currentItem: {
        fileName: "IMG_8754.TRIM.MOV",
        latitude: 22.349,
        longitude: 114.1058,
        origURL: "assets-library://asset/asset.MOV?id=64BAF71C-2DC8-4796-9C8A-2C37FA18044F&ext=MOV",
        timestamp: "2019-03-15T12:15:02Z",
        uri: "file:///Users/james/Library/Developer/CoreSimulator/Devices/155D8B2A-5E3F-4CFA-9A2B-EF760F5A0F80/data/Containers/Data/Application/2A09ED40-3BF5-4189-B260-D3E05FF7F9B9/Documents/images/BB856449-EEBB-4FCD-AC9B-81CC5371868D.MOV",
      },
      paused: true,
      playButtonTitle: 'Play',
    }
  }
  renderProgressBar = (progress) => (
    <ProgressBar progress={progress} />
  )

  showVideoTrimmer = () => {
    const { currentItem } = this.state;
    if(!_.isEmpty(currentItem)) {
      const uri = currentItem.origURL;
      if(!_.isEmpty(uri)) {
        RNVideoTrimmer.showVideoTrimmer({
          uri,
          maxLength: this.getMaxDuration(currentItem.duration),
          minLength: this.getMinDuration(currentItem.duration),
        }, (res) => {
          if (res.error === undefined) {
            console.log(res);
            // this.props.trimmedVideoLength(
            //   currentItem,
            //   res.startTime,
            //   res.endTime,
            // );
            // this.props.navigation.setParams({
            //   title: this.getHeaderTitle(),
            // });
            // this.setState({ paused: false });
          }
        });
      }
    }
  }

  showImagePciker = () => {
    ImagePicker.showImagePicker(options, (response) => {
      console.log('Response = ', response);
    
      if (response.didCancel) {
        console.log('User cancelled image picker');
      } else if (response.error) {
        console.log('ImagePicker Error: ', response.error);
      } else if (response.customButton) {
        console.log('User tapped custom button: ', response.customButton);
      } else {
        // You can also display the image using data:
        // const source = { uri: 'data:image/jpeg;base64,' + response.data };
        console.log('response', response);
        this.setState({
          currentItem: response,
        });
      }
    });
  }

  palyVideo = () => {
    const paused = !this.state.paused;

    this.setState({ paused , playButtonTitle: paused ? 'Play' : 'Pause'});
  }

  getMaxDuration = (duration) => (
		_.isEmpty(duration)
			? 15
			: duration
	)

	getMinDuration = (duration) => (
		_.isEmpty(duration)
			? 3
			: duration
	)

  render() {
    return (
      <View style={styles.container}>
        {
          (!_.isEmpty(this.state.currentItem)) &&
          <Video source={{uri: this.state.currentItem.uri}}   // Can be a URL or a local file.
            ref={(ref) => {
              this.player = ref
            }}  // Store reference
            paused={this.state.paused}
            style={styles.backgroundVideo}
          />
        }
        <SafeAreaView style={{ flex: 1, justifyContent: 'flex-end' }}>
          <Button title="pick" onPress={this.showImagePciker} />
          <Button title={ this.state.playButtonTitle } onPress={this.palyVideo}/>
          <Button title="trim" onPress={this.showVideoTrimmer} />
        </SafeAreaView>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignContent: 'center',
  },
  backgroundVideo: {
    position: 'absolute',
    top: 0,
    left: 0,
    bottom: 0,
    right: 0,
  },
});
