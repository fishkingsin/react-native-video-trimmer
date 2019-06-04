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
  Text,
} from 'react-native';
import ImagePicker from 'react-native-image-picker';
import RNVideoTrimmer from 'react-native-video-trimmer';
import Slider from '@react-native-community/slider';
import Video from 'react-native-video';
import _ from 'lodash';
import PropTypes from 'prop-types';
import queryString from 'query-string';
 

const isIOS = _.isEqual(Platform.OS, 'ios');

const format = (time) => {
  var sec_num = parseInt(time, 10); // don't forget the second param
  var hours   = Math.floor(sec_num / 3600);
  var minutes = Math.floor((sec_num - (hours * 3600)) / 60);
  var seconds = sec_num - (hours * 3600) - (minutes * 60);

  if (hours   < 10) {hours   = "0"+hours;}
  if (minutes < 10) {minutes = "0"+minutes;}
  if (seconds < 10) {seconds = "0"+seconds;}
  return hours+':'+minutes+':'+seconds;
}

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
      range: {
        start: 0,
        end: 1.0,
      },
      duration: 0,
      currentProgress: 0,
      currentItem: {
        path: "/storage/emulated/0/DCIM/IMG_8754.TRIM.MOV",
        uri: "content://com.google.android.apps.photos.contentprovider/-1/2/content%3A%2F%2Fmedia%2Fexternal%2Fvideo%2Fmedia%2F135/ORIGINAL/NONE/1049152015",

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
      const uri = isIOS ? currentItem.origURL : currentItem.uri;
      console.log('uri = ', uri);
      if(!_.isEmpty(uri)) {
        RNVideoTrimmer.showVideoTrimmer({
          uri,
          maxLength: this.getMaxDuration(currentItem.duration),
          minLength: this.getMinDuration(currentItem.duration),
        }, (res) => {
          if (res.error === undefined) {
            console.log(res);
            const currentProgress = _.isEqual(this.state.duration, 0) ? 0 : res.startTime / this.state.duration;
            this.setState({
              range: {
                start: res.startTime,
                end: res.endTime,    
              },
              currentProgress,
            })
            this.player.seek(res.startTime);
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
    ImagePicker.launchImageLibrary(options, (response) => {
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
    if (this.player !== undefined) {
      this.setState({ paused , playButtonTitle: paused ? 'Play' : 'Pause', currentProgress: this.state.range.start / this.state.duration }, () => {
        this.player.seek(this.state.currentProgress * this.state.duration);
      });

      
    }
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
  
  onProgress = ({
    currentTime,
    playableDuration,
    seekableDuration,
  }) => {
    if ( currentTime > this.state.range.end) {
      this.setState({ currentProgress: this.state.range.start / this.state.duration, paused: true});
    } else {
    
      this.setState({ currentProgress: currentTime / this.state.duration });
    }
  }

  onLoad = ({ duration }) => {
    this.setState({ duration, currentProgress: 0, range: { start: 0, end: duration} });
  }
  
  onEnd = () => {
    this.setState({ currentProgress: this.state.range.start, paused: true, playButtonTitle: 'Play' });
    this.player.seek(0);
  }

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
            onProgress={this.onProgress}
            onLoad={this.onLoad}
            onEnd={this.onEnd}
          />
        }
        <SafeAreaView style={{ flex: 1, justifyContent: 'flex-end' }}>

          { this.player !== undefined &&
            <View style={styles.progressView} >
              <Text>{
                format(this.state.currentProgress * this.state.duration)
              }</Text>
              <Slider
                style={{ flex: 1 }}
                minimumValue={0}
                maximumValue={1}
                minimumTrackTintColor="#FFFFFF"
                maximumTrackTintColor="#A0A0A0"
                value={this.state.currentProgress}
              />
                <Text>{
                  format(this.state.duration)
                }</Text>
            </View>
          }
          
          <Button style={styles.button} title="pick" onPress={this.showImagePciker} />
          <Button style={styles.button}  title={ this.state.playButtonTitle } onPress={this.palyVideo}/>
          <Button style={styles.button} title="trim" onPress={this.showVideoTrimmer} />
        </SafeAreaView>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  progressView: {
    backgroundColor: '#FFFFFFAA',
    flexDirection: 'row',
    margin: 5,
  },
  container: {
    backgroundColor: 'white',
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
    backgroundColor: 'white',
  },
  button: {
    padding: 3,
  }
});
