//
//  ViewController.swift
//  Lectorem
//
//  Created by Rodolfo Dalla Costa on 21/06/19.
//

import UIKit
import MobileCoreServices
import TesseractOCR
import AVFoundation
import CoreImage


class ViewController: UIViewController, G8TesseractDelegate {

    @IBOutlet weak var ImageText: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let tesseract = G8Tesseract(language: "por") {
            tesseract.delegate = self;
        }
    }

    
    @IBAction func BtnFonte(_ sender: Any) {
        let imagePickerActionSheet =
            UIAlertController(title: "Selecione uma fonte de imagem",
                              message: nil,
                              preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraButton = UIAlertAction(
                title: "Câmera",
                style: .default) { (alert) -> Void in
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = self
                    imagePicker.sourceType = .camera
                    imagePicker.mediaTypes = [kUTTypeImage as String]
                    self.present(imagePicker, animated: true, completion: {
                    })
                    
            }
            imagePickerActionSheet.addAction(cameraButton)
        }
        
        let libraryButton = UIAlertAction(
            title: "Galeria",
            style: .default) { (alert) -> Void in
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary
                imagePicker.mediaTypes = [kUTTypeImage as String]
        }
        imagePickerActionSheet.addAction(libraryButton)
        let cancelButton = UIAlertAction(title: "Cancelar", style: .cancel)
        imagePickerActionSheet.addAction(cancelButton)
        present(imagePickerActionSheet, animated: true)
    }

    @IBOutlet weak var sourceBtn: UITextView!
}

extension ViewController: UINavigationControllerDelegate {
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let selectedPhoto =
            info[.originalImage] as? UIImage else {
                dismiss(animated: true)
                return
        }
        dismiss(animated: true) {
            self.performImageRecognition(selectedPhoto)
        }
        
    }
    
    func performImageRecognition(_ image: UIImage) {
        
        let scaledImage = image.scaledImage(1000) ?? image
        
        if let tesseract = G8Tesseract(language: "por") {
            ImageText.text = "Processando"
            tesseract.engineMode =  .lstmOnly
            tesseract.pageSegmentationMode = .autoOSD
            tesseract.image = scaledImage;
            print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
            print(tesseract.deskewAngle)
            print(tesseract.orientation.rawValue)
            print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
            if(tesseract.orientation == .pageUp)
            {
                let ut = AVSpeechUtterance(string: "Iniciando processamento")
                ut.voice = AVSpeechSynthesisVoice(language: "pt-BR")
                AVSpeechSynthesizer().speak(ut)
                //synthesizer.speak(ut)
                tesseract.recognize()
                print("************___")
                print(tesseract.progress)
                if(tesseract.recognizedText.trimmingCharacters(in: [" ", "\n"]).isEmpty){
                    ImageText.text = "Não foi possível reconhecer nenhum texto\n Por favor, tente novamente"
                } else {
                    ImageText.text = tesseract.recognizedText
                }
                
            } else {
                var orientationInfo = "";
                switch(tesseract.orientation){
                case .pageRight:
                    orientationInfo = "O texto está torto para a direita\nGire-o para a vertical no sentido anti-horário"
                        break;
                case .pageLeft:
                    orientationInfo = "O texto está torto para a esquerda, gire-o para a vertical no sentido horário"
                        break;
                case .pageDown:
                    orientationInfo = "O texto está de cabeça para baixo"
                        break;
                default:
                    orientationInfo = "O texto aparenta estar torto,\n Por favor, coloque-o na vertical"
                }
                ImageText.text = orientationInfo
            }
            
        }
        
        let utterance = AVSpeechUtterance(string: ImageText.text)
        utterance.voice = AVSpeechSynthesisVoice(language: "pt-BR")

        AVSpeechSynthesizer().speak(utterance)
    }
}


extension UIImage {
    func scaledImage(_ maxDimension: CGFloat) -> UIImage? {
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        
        if size.width > size.height {
            scaledSize.height = size.height / size.width * scaledSize.width
        } else {
            scaledSize.width = size.width / size.height * scaledSize.height
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        draw(in: CGRect(origin: .zero, size: scaledSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
}
