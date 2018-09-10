using ReactNative.Bridge;
using System;
using System.Collections.Generic;
using Windows.ApplicationModel.Core;
using Windows.UI.Core;

namespace Video.Trimmer.RNVideoTrimmer
{
    /// <summary>
    /// A module that allows JS to share data.
    /// </summary>
    class RNVideoTrimmerModule : NativeModuleBase
    {
        /// <summary>
        /// Instantiates the <see cref="RNVideoTrimmerModule"/>.
        /// </summary>
        internal RNVideoTrimmerModule()
        {

        }

        /// <summary>
        /// The name of the native module.
        /// </summary>
        public override string Name
        {
            get
            {
                return "RNVideoTrimmer";
            }
        }
    }
}
