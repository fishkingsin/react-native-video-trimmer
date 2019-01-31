
package com.creedon.reactlibrary.videotrimmer;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.support.annotation.NonNull;

import com.creedon.androidVideoTrimmer.features.trim.VideoTrimmerActivity;
import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeArray;
import com.tbruyelle.rxpermissions2.RxPermissions;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.Iterator;

import iknow.android.utils.BaseUtils;
import io.reactivex.functions.Consumer;

import static android.app.Activity.RESULT_OK;
import static com.creedon.androidVideoTrimmer.features.trim.VideoTrimmerActivity.VIDEO_TRIM_REQUEST_CODE;

public class RNVideoTrimmerModule extends ReactContextBaseJavaModule implements ActivityEventListener {

	private final ReactApplicationContext reactContext;
	private static final String E_ACTIVITY_DOES_NOT_EXIST = "E_ACTIVITY_DOES_NOT_EXIST";
	private static final String NO_RESULT_ERROR = "NO_RESULT_ERROR";
	private static final String PERMISSION_DENIED_ERROR = "PERMISSION_DENIED";
	private static final String PHOTO_LIBRARY_PERMISSIONS_NOT_GRANTED = "Photo library permissions not granted";
	private static final String VIDEO_PATH_KEY = "VIDEO_PATH_KEY";
    private ReadableMap options;
    private Callback callback;
	public RNVideoTrimmerModule(ReactApplicationContext reactContext) {
		super(reactContext);
		this.reactContext = reactContext;
		this.reactContext.addActivityEventListener(this);
		BaseUtils.init(this.reactContext);
	}

	public Context getContext() {
		return getReactApplicationContext();
	}

	@SuppressLint("CheckResult")
	@ReactMethod
	public void showVideoTrimmer(final ReadableMap options, Callback callback) {
		this.options = options;
		final Activity activity = getCurrentActivity();
        this.callback = callback;
		if (activity == null) {
            this.callback.invoke(E_ACTIVITY_DOES_NOT_EXIST, "Activity doesn't exist");
			return;
		}
		this.getCurrentActivity().runOnUiThread(new Runnable() {
			@Override
			public void run() {
				RxPermissions rxPermissions = new RxPermissions(RNVideoTrimmerModule.this.getCurrentActivity());
				try {
					rxPermissions.request(Manifest.permission.READ_EXTERNAL_STORAGE).subscribe(new Consumer<Boolean>() {
						@Override
						public void accept(Boolean granted) throws Exception {

							if (granted) {
								Bundle bundle = new Bundle();
								String videoPath = "";
								bundle.putString(VIDEO_PATH_KEY, videoPath);
								Intent intent = new Intent(getReactApplicationContext(), VideoTrimmerActivity.class);
								intent.putExtras(bundle);
								reactContext.startActivityForResult(intent, VIDEO_TRIM_REQUEST_CODE, bundle);
							} else {
								RNVideoTrimmerModule.this.callback.invoke(PERMISSION_DENIED_ERROR, PHOTO_LIBRARY_PERMISSIONS_NOT_GRANTED);
							}
						}
					});
				}catch (Exception e) {
					RNVideoTrimmerModule.this.callback.invoke(e.getMessage());
				}
			}
		});

	}

	@Override
	public String getName() {
		return "RNVideoTrimmer";
	}

	public @NonNull
	Activity getActivity() {
		return getCurrentActivity();
	}


	@Override
	public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
		if (requestCode == VIDEO_TRIM_REQUEST_CODE ){
			if(resultCode == RESULT_OK && data != null) {
				JSONArray response = new JSONArray();
				try {
					this.callback.invoke(convertJsonToArray(response));
				} catch (JSONException e) {
					this.callback.invoke(e.getMessage());
				}
			} else {
				this.callback.invoke(NO_RESULT_ERROR, NO_RESULT_ERROR);
			}
		}
	}

	@Override
	public void onNewIntent(Intent intent) {

	}
	private static WritableMap convertJsonToMap(JSONObject jsonObject) throws JSONException {
		WritableMap map = Arguments.createMap();

		Iterator<String> iterator = jsonObject.keys();
		while (iterator.hasNext()) {
			String key = iterator.next();
			Object value = jsonObject.get(key);
			if (value instanceof JSONObject) {
				map.putMap(key, convertJsonToMap((JSONObject) value));
			} else if (value instanceof JSONArray) {
				map.putArray(key, convertJsonToArray((JSONArray) value));
			} else if (value instanceof Boolean) {
				map.putBoolean(key, (Boolean) value);
			} else if (value instanceof Integer) {
				map.putInt(key, (Integer) value);
			} else if (value instanceof Double) {
				map.putDouble(key, (Double) value);
			} else if (value instanceof String) {
				map.putString(key, (String) value);
			} else {
				map.putString(key, value.toString());
			}
		}
		return map;
	}

	private static WritableArray convertJsonToArray(JSONArray jsonArray) throws JSONException {
		WritableArray array = new WritableNativeArray();

		for (int i = 0; i < jsonArray.length(); i++) {
			Object value = jsonArray.get(i);
			if (value instanceof JSONObject) {
				array.pushMap(convertJsonToMap((JSONObject) value));
			} else if (value instanceof JSONArray) {
				array.pushArray(convertJsonToArray((JSONArray) value));
			} else if (value instanceof Boolean) {
				array.pushBoolean((Boolean) value);
			} else if (value instanceof Integer) {
				array.pushInt((Integer) value);
			} else if (value instanceof Double) {
				array.pushDouble((Double) value);
			} else if (value instanceof String) {
				array.pushString((String) value);
			} else {
				array.pushString(value.toString());
			}
		}
		return array;
	}
}
