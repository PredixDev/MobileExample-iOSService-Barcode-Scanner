
var Scanner = function()
{
  var textarea = null;

  this.scanBarcode = function(idTextArea)
  {
    if (null == textarea) {
      textarea = idTextArea;
    }

    var getDocServiceURL = 'http://pmapi/barcodescanner';
    console.log('getDocServiceURL: '+ getDocServiceURL);

    //sending GET request to db service to fetch document.
    _sendGETRequest(getDocServiceURL, function(data) {
      var barcodeRcvd = JSON.stringify(data);
      console.log('Barcode: '+ barcodeRcvd);
      textarea.value = barcodeRcvd;

    }, function(err) {
      console.error('Something went wrong:', err);
    });
  };

  // sends a GET HTTP request
  var _sendGETRequest = function(url, successHandler, errorHandler) {
    var xhr = new XMLHttpRequest();
    xhr.open('get', url, true);
    xhr.responseType = 'json';
    xhr.onload = function() {
      var status = xhr.status;
      if (status >= 200 && status <= 299) {
        successHandler && successHandler(xhr.response);
      } else {
        errorHandler && errorHandler(status);
      }
    };
    xhr.send();
  };


}

var scanner = new Scanner();
