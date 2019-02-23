package com.creedon.reactlibrary.videotrimmer.widget;

import android.content.Context;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.os.Build;
import android.util.AttributeSet;
import android.util.Log;
import android.widget.VideoView;
/**
 * _   _ _______   ________ _       _____   __
 * | \ | |_   _\ \ / /| ___ \ |     / _ \ \ / /
 * |  \| | | |  \ V / | |_/ / |    / /_\ \ V /
 * | . ` | | |  /   \ |  __/| |    |  _  |\ /
 * | |\  |_| |_/ /^\ \| |   | |____| | | || |
 * \_| \_/\___/\/   \/\_|   \_____/\_| |_/\_/
 * <p>
 * modified by jameskong on 12/2/2019.
 */
/**
 * author : J.Chou
 * e-mail : who_know_me@163.com
 * time   : 2018/10/20 11:22 AM
 * version: 1.0
 * description:
 */
public class ZVideoView extends VideoView {
  private int mVideoWidth = 480;
  private int mVideoHeight = 480;
  private int videoRealW = 1;
  private int videoRealH = 1;
  private DisplayMode displayMode;

  public void setDisplayMode(DisplayMode displayMode) {
    this.displayMode = displayMode;
  }

  public enum DisplayMode {
    ORIGINAL,       // original aspect ratio
    FULL_SCREEN,    // fit to screen
    ZOOM            // zoom in
  };

  public ZVideoView(Context context) {
    super(context);
  }

  public ZVideoView(Context context, AttributeSet attrs) {
    super(context, attrs);
  }

  public ZVideoView(Context context, AttributeSet attrs, int defStyleAttr) {
    super(context, attrs, defStyleAttr);
  }

  @Override
  public void setVideoURI(Uri uri) {
    super.setVideoURI(uri);
    MediaMetadataRetriever retr = new MediaMetadataRetriever();
    retr.setDataSource(uri.getPath());
    String height = retr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT);
    String width = retr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH);
    int r = 0;
    if (Build.VERSION.SDK_INT >= 17) {
      String rotation = retr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION);

      Log.d("@@@", "Rotation: "+rotation);
      r = Integer.parseInt(rotation);
    }
    try {
      if (r==0) {
        mVideoHeight = videoRealH = Integer.parseInt(height);
        mVideoWidth = videoRealW = Integer.parseInt(width);
      } else {
        mVideoHeight = videoRealH = Integer.parseInt(width);
        mVideoWidth = videoRealW = Integer.parseInt(height);
      }
    } catch (NumberFormatException e) {
      e.printStackTrace();
    }
  }


  @Override
  protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
     Log.i("@@@", "onMeasure");
    int width = getDefaultSize(mVideoWidth, widthMeasureSpec);
    int height = getDefaultSize(mVideoHeight, heightMeasureSpec);
    if (mVideoWidth > 0 && mVideoHeight > 0) {
      if (mVideoWidth > mVideoHeight) {
         Log.i("@@@", "image too tall, correcting");
        height = width * mVideoHeight / mVideoWidth;
        Log.i("@@@", "width: "+height);
      } else if (mVideoWidth < mVideoHeight) {
         Log.i("@@@", "image too wide, correcting");

        width = height * mVideoWidth / mVideoHeight;
        Log.i("@@@", "width: "+width);
      } else {
        // Log.i("@@@", "aspect ratio is correct: " +
        // width+"/"+height+"="+
        // mVideoWidth+"/"+mVideoHeight);
      }
    }
    // Log.i("@@@", "setting size: " + width + 'x' + height);
    setMeasuredDimension(width, height);

  }
}
